package com.ottogroup.emfavro

import com.google.common.base.Preconditions
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.emf.ecore.EcorePackage

class IDLGenerator {
    package static val ERROR_MESSAGE_MISSING_GEN_PACKAGE = "The GenModel contains no GenPackage"

    def String generateIdl(GenModel genModel) {
        Preconditions.checkArgument(!genModel.genPackages.empty, ERROR_MESSAGE_MISSING_GEN_PACKAGE)
        '''
        @namespace("«genModel.genPackages.head.basePackage»")
        protocol «genModel.modelName» {
            «FOR genPackage : genModel.genPackages»
            «FOR eClassifier : genPackage.classifiersToGenerate»
            «eClassifier.idlTypeDefinition(genPackage.basePackage, genModel)»
            «ENDFOR»
            «ENDFOR»
        }
        '''
    }

    package def getClassifiersToGenerate(GenPackage genPackage) {
        genPackage.getEcorePackage.EClassifiers
        	.filter[!(it instanceof EClass && (it as EClass).abstract)]
        	.filter[!(it instanceof EDataType && !(it instanceof EEnum))]
    }

    package def dispatch idlTypeDefinition(EEnum eEnum, String basePackage, GenModel genModel) '''
        @namespace("«basePackage».«eEnum.EPackage.name».avro")
        enum «eEnum.name» {
            «FOR literal : eEnum.ELiterals SEPARATOR ', '»«literal.name»«ENDFOR»
        }
    '''

    package def dispatch idlTypeDefinition(EClass eClass, String basePackage, GenModel genModel) '''
        @namespace("«basePackage».«eClass.EPackage.name».avro")
        record «eClass.name» {
            «FOR EStructuralFeature feature : eClass.EAllStructuralFeatures»
            «feature.findAvroType(basePackage, genModel)» «feature.name»;
            «ENDFOR»
        }
    '''

    package def dispatch findAvroType(EReference eRef, String basePackage, GenModel genModel) {
        val type = eRef.EReferenceType
        if (type.isInterface) {
            return '''union { «FOR impl : type.findImplementations(genModel) SEPARATOR ", "»«basePackage».«impl.EPackage.name».avro.«impl.name»«ENDFOR» }'''
        } else {
            return '''«basePackage».«type.EPackage.name».avro.«type.name»'''
        }
    }

    package def dispatch findAvroType(EAttribute eAttr, String basePackage, GenModel genModel) {
        val type = eAttr.EAttributeType
        switch (type) {
            case EcorePackage.Literals.EBOOLEAN,
            case EcorePackage.Literals.EINT,
            case EcorePackage.Literals.ELONG,
            case EcorePackage.Literals.EFLOAT,
            case EcorePackage.Literals.EDOUBLE: return type.instanceClassName
            EEnum: '''«basePackage».«type.EPackage.name».avro.«type.name»'''
            default: return "string"
        }
    }

    package def findImplementations(EClassifier intrface, GenModel genModel) {
        genModel.genPackages.map[getEcorePackage.EClassifiers]
            .flatten
            .filter[it instanceof EClass]
            .filter[isImplementation(intrface as EClass)]
            .toSet
    }

    package def isImplementation(EClassifier classifier, EClass intrface) {
        if (classifier instanceof EClass) {
            return (!classifier.isAbstract) && (intrface.isSuperTypeOf(classifier));
        }
        return false;
    }
}