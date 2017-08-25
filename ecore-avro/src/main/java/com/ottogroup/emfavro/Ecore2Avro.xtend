package com.ottogroup.emfavro

import com.google.common.base.Preconditions
import org.apache.avro.Protocol
import org.apache.avro.Schema
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EDataType
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage

class Ecore2Avro {
    static def Protocol convert(GenModel genModel) {
        Preconditions.checkArgument(!genModel.genPackages.empty)

        val protocol = new Protocol(genModel.modelName, genModel.genPackages.head.basePackage)
        val schemas = genModel.genPackages
            .map[it -> classifiersToGenerate]
            .map[
                val basePackage = key.basePackage
                value.map[toAvroSchema(basePackage, genModel)]
            ].flatten

        protocol.setTypes(schemas.toList)
        protocol
    }

    package static def getClassifiersToGenerate(GenPackage genPackage) {
        genPackage.getEcorePackage.EClassifiers
            .filter[!(it instanceof EClass && (it as EClass).abstract)]
            .filter[!(it instanceof EDataType && !(it instanceof EEnum))]
    }

    package static def dispatch Schema toAvroSchema(EEnum eEnum, String basePackage, GenModel genModel) {
        Schema.createEnum(eEnum.name, null, '''«basePackage».«eEnum.EPackage.name».avro''',
            eEnum.ELiterals.map[name])
    }

    package static def dispatch Schema toAvroSchema(EClass eClass, String basePackage, GenModel genModel) {
        Schema.createRecord(eClass.name, null, '''«basePackage».«eClass.EPackage.name».avro''',
            false, eClass.EAllStructuralFeatures.map[toAvroField(basePackage, genModel)])
    }

    package static def dispatch Schema toAvroSchema(EDataType eDataType, String basePackage, GenModel genModel) {
        switch (eDataType) {
            case EcorePackage.Literals.EBOOLEAN: Schema.create(Schema.Type.BOOLEAN)
            case EcorePackage.Literals.EINT: Schema.create(Schema.Type.INT)
            case EcorePackage.Literals.ELONG: Schema.create(Schema.Type.LONG)
            case EcorePackage.Literals.EFLOAT: Schema.create(Schema.Type.FLOAT)
            case EcorePackage.Literals.EDOUBLE: Schema.create(Schema.Type.DOUBLE)
            EEnum: eDataType.toAvroSchema(basePackage, genModel)
            default: Schema.create(Schema.Type.STRING)
        }
    }

    package static def dispatch Schema.Field toAvroField(EReference eRef, String basePackage, GenModel genModel) {
        val type = eRef.EReferenceType
        var Schema schema
        if (type.isInterface) {
            schema = Schema.createUnion(type.findImplementations(genModel)
                .map[it.toAvroSchema(basePackage, genModel)]
                .toList)
        } else {
            schema = type.toAvroSchema(basePackage, genModel)
        }

        if (eRef.upperBound == -1 || eRef.upperBound > 1) {
            schema = Schema.createArray(schema)
        }

        new Schema.Field(eRef.name, schema, null, null as Object)
    }

    package static def dispatch Schema.Field toAvroField(EAttribute eAttr, String basePackage, GenModel genModel) {
        var Schema schema = eAttr.EAttributeType.toAvroSchema(basePackage, genModel)
        if (eAttr.upperBound == -1 || eAttr.upperBound > 1) {
            schema = Schema.createArray(schema)
        }

        new Schema.Field(eAttr.name, schema, null, null as Object)
    }

    package static def findImplementations(EClassifier intrface, GenModel genModel) {
        genModel.genPackages.map[getEcorePackage.EClassifiers]
            .flatten
            .filter[it instanceof EClass]
            .filter[isImplementation(intrface as EClass)]
    }

    package static def isImplementation(EClassifier classifier, EClass intrface) {
        if (classifier instanceof EClass) {
            (!classifier.isAbstract) && (intrface.isSuperTypeOf(classifier))
        } else false
    }
}