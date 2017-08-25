package com.ottogroup.emfavro

import java.util.Date
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenPackage
import org.eclipse.emf.common.util.BasicEList
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EDataType
import org.eclipse.emf.ecore.EEnum
import org.eclipse.emf.ecore.EEnumLiteral
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EcorePackage
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat
import static org.assertj.core.api.Assertions.assertThatExceptionOfType
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.when

class IDLGeneratorTest {

    @Test
    def void shouldNotAcceptMissingGenPackage() {
        // given
        val genModelMock = mock(GenModel)
        when(genModelMock.genPackages).thenReturn(new BasicEList)
        when(genModelMock.modelName).thenReturn("Test Model")
        val idlGenerator = new IDLGenerator

        // when // then
        assertThatExceptionOfType(IllegalArgumentException)
            .isThrownBy([idlGenerator.generateIdl(genModelMock)])
            .withMessage(IDLGenerator.ERROR_MESSAGE_MISSING_GEN_PACKAGE)
    }

    @Test
    def void shouldIgnoreAbstractClasses() {
        // given
        val abstractClass = mock(EClass)
        when(abstractClass.abstract).thenReturn(true)

        val concreteClass = mock(EClass)

        val ecorePackage = mock(EcorePackage)
        when(ecorePackage.EClassifiers).thenReturn(new BasicEList(#[abstractClass, concreteClass]))

        val genPackage = mock(GenPackage)
        when(genPackage.getEcorePackage).thenReturn(ecorePackage)

        val idlGenerator = new IDLGenerator

        // when 
        val classifiersToGenerate = idlGenerator.getClassifiersToGenerate(genPackage)
        
        // then
		assertThat(classifiersToGenerate).containsOnly(concreteClass)
    }
    
    @Test
    def void shouldIgnoreDataTypes() {
        // given
        val dataType = mock(EDataType)
        val concreteClass = mock(EClass)

        val ecorePackage = mock(EcorePackage)
        when(ecorePackage.EClassifiers).thenReturn(new BasicEList(#[dataType, concreteClass]))

        val genPackage = mock(GenPackage)
        when(genPackage.getEcorePackage).thenReturn(ecorePackage)

        val idlGenerator = new IDLGenerator

        // when 
        val classifiersToGenerate = idlGenerator.getClassifiersToGenerate(genPackage)
        
        // then
		assertThat(classifiersToGenerate).containsOnly(concreteClass)
    }

    @Test
    def void shouldGenerateEnumCorrectly() {
        // given
        val literalMock1 = mock(EEnumLiteral)
        val literalMock2 = mock(EEnumLiteral)
        val literalMock3 = mock(EEnumLiteral)

        when(literalMock1.name).thenReturn("Literal1")
        when(literalMock2.name).thenReturn("Literal2")
        when(literalMock3.name).thenReturn("Literal3")

        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val enumMock = mock(EEnum)
        when(enumMock.name).thenReturn("TestEnum")
        when(enumMock.ELiterals).thenReturn(new BasicEList(#[literalMock1, literalMock2, literalMock3]))
        when(enumMock.EPackage).thenReturn(ePackageMock)

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[enumMock]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator

        // when
        val String idl = generator.idlTypeDefinition(enumMock, genPackageMock.basePackage, genModelMock).toString

        // then
        val String expected = '''
        @namespace("com.base.package.leaf.avro")
        enum TestEnum {
            Literal1, Literal2, Literal3
        }
        '''
        assertThat(idl).isEqualTo(expected)
    }

    @Test
    def void shouldFindAvroTypeForPrimitives() {
        // given
        val booleanAttr = mock(EAttribute)
        val intAttr = mock(EAttribute)
        val longAttr = mock(EAttribute)
        val floatAttr = mock(EAttribute)
        val doubleAttr = mock(EAttribute)
        val stringAttr = mock(EAttribute)
        val wrappingAttr = mock(EAttribute)

        val ownDataTypeMock = mock(EDataType)
        when(ownDataTypeMock.instanceClass).thenReturn(Date)

        when(booleanAttr.name).thenReturn("booleanAttr")
        when(booleanAttr.EAttributeType).thenReturn(EcorePackage.Literals.EBOOLEAN)
        when(intAttr.name).thenReturn("intAttr")
        when(intAttr.EAttributeType).thenReturn(EcorePackage.Literals.EINT)
        when(longAttr.name).thenReturn("longAttr")
        when(longAttr.EAttributeType).thenReturn(EcorePackage.Literals.ELONG)
        when(floatAttr.name).thenReturn("floatAttr")
        when(floatAttr.EAttributeType).thenReturn(EcorePackage.Literals.EFLOAT)
        when(doubleAttr.name).thenReturn("doubleAttr")
        when(doubleAttr.EAttributeType).thenReturn(EcorePackage.Literals.EDOUBLE)
        when(stringAttr.name).thenReturn("stringAttr")
        when(stringAttr.EAttributeType).thenReturn(EcorePackage.Literals.ESTRING)
        when(wrappingAttr.name).thenReturn("wrappingAttr")
        when(wrappingAttr.EAttributeType).thenReturn(ownDataTypeMock)

        val generator = new IDLGenerator

        // when // then
        assertThat(generator.findAvroType(booleanAttr, null, null)).isEqualTo("boolean")
        assertThat(generator.findAvroType(intAttr, null, null)).isEqualTo("int")
        assertThat(generator.findAvroType(longAttr, null, null)).isEqualTo("long")
        assertThat(generator.findAvroType(floatAttr, null, null)).isEqualTo("float")
        assertThat(generator.findAvroType(doubleAttr, null, null)).isEqualTo("double")
        assertThat(generator.findAvroType(stringAttr, null, null)).isEqualTo("string")
        assertThat(generator.findAvroType(wrappingAttr, null, null)).isEqualTo("string")
    }

    @Test
    def void shouldFindAvroTypeForClass() {
        // given
        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val classMock = mock(EClass)
        when(classMock.name).thenReturn("TestClass")
        when(classMock.EPackage).thenReturn(ePackageMock)

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[classMock]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val ref = mock(EReference)
        when(ref.name).thenReturn("ref")
        when(ref.EReferenceType).thenReturn(classMock)

        val otherPackageMock = mock(EPackage)
        when(otherPackageMock.name).thenReturn("other")

        val containerClassMock = mock(EClass)
        when(containerClassMock.name).thenReturn("ContainerClass")
        when(containerClassMock.EPackage).thenReturn(otherPackageMock)
        when(containerClassMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[ref]))

        val generator = new IDLGenerator

        // when 
        val concreteAvroType = generator.findAvroType(ref, genPackageMock.basePackage, genModelMock)
        
        // then
		assertThat(concreteAvroType).isEqualTo("com.base.package.leaf.avro.TestClass")
    }

    @Test
    def void shouldFindAvroTypeForInterface() {
        // given
        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val intrfaceMock = mock(EClass)
        when(intrfaceMock.name).thenReturn("MyInterface")
        when(intrfaceMock.interface).thenReturn(true)
        when(intrfaceMock.abstract).thenReturn(true)
        when(intrfaceMock.EPackage).thenReturn(ePackageMock);

        val impl1 = mock(EClass)
        when(impl1.name).thenReturn("MyInterfaceImpl1")
        when(impl1.EPackage).thenReturn(ePackageMock)
        when(intrfaceMock.isSuperTypeOf(impl1)).thenReturn(true)

        val impl2 = mock(EClass)
        when(impl2.name).thenReturn("MyInterfaceImpl2")
        when(impl2.EPackage).thenReturn(ePackageMock)
        when(intrfaceMock.isSuperTypeOf(impl2)).thenReturn(true)

        val ref = mock(EReference)
        when(ref.name).thenReturn("ref")
        when(ref.EReferenceType).thenReturn(intrfaceMock)

        val container = mock(EClass)
        when(container.name).thenReturn("Container")
        when(container.EAllStructuralFeatures).thenReturn(new BasicEList(#[ref]))

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[
            intrfaceMock, impl1, impl2, container]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator

        // when 
        val avroUnionType = generator.findAvroType(ref, genPackageMock.basePackage, genModelMock)
        
        // then
        val expected = "union { com.base.package.leaf.avro.MyInterfaceImpl1, com.base.package.leaf.avro.MyInterfaceImpl2 }"
		assertThat(avroUnionType).isEqualTo(expected)
    }
    
    @Test
    def void shouldFindImplementations() {
    	// given
        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val intrfaceMock = mock(EClass)
        when(intrfaceMock.name).thenReturn("MyInterface")
        when(intrfaceMock.interface).thenReturn(true)
        when(intrfaceMock.abstract).thenReturn(true)
        when(intrfaceMock.EPackage).thenReturn(ePackageMock);

        val impl1 = mock(EClass)
        when(impl1.name).thenReturn("MyInterfaceImpl1")
        when(impl1.EPackage).thenReturn(ePackageMock)
        when(intrfaceMock.isSuperTypeOf(impl1)).thenReturn(true)

        val impl2 = mock(EClass)
        when(impl2.name).thenReturn("MyInterfaceImpl2")
        when(impl2.EPackage).thenReturn(ePackageMock)

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[
            intrfaceMock, impl1, impl2]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator
        
        // when
        val impls = generator.findImplementations(intrfaceMock, genModelMock)
        
        // then
        assertThat(impls).containsOnly(impl1)
    }

    @Test
    def void shouldGenerateRecordAttributesCorrectly() {
        // given
        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val booleanAttr = mock(EAttribute)
        val intAttr = mock(EAttribute)
        val longAttr = mock(EAttribute)
        val floatAttr = mock(EAttribute)
        val doubleAttr = mock(EAttribute)
        val stringAttr = mock(EAttribute)
        val enumAttr = mock(EAttribute)
        val wrappingAttr = mock(EAttribute)

        val ownDataTypeMock = mock(EDataType)
        when(ownDataTypeMock.instanceClass).thenReturn(Date)

        val enumMock = mock(EEnum)
        when(enumMock.name).thenReturn("MyEnum")
        when(enumMock.EPackage).thenReturn(ePackageMock)

        when(booleanAttr.name).thenReturn("booleanAttr")
        when(booleanAttr.EAttributeType).thenReturn(EcorePackage.Literals.EBOOLEAN)
        when(intAttr.name).thenReturn("intAttr")
        when(intAttr.EAttributeType).thenReturn(EcorePackage.Literals.EINT)
        when(longAttr.name).thenReturn("longAttr")
        when(longAttr.EAttributeType).thenReturn(EcorePackage.Literals.ELONG)
        when(floatAttr.name).thenReturn("floatAttr")
        when(floatAttr.EAttributeType).thenReturn(EcorePackage.Literals.EFLOAT)
        when(doubleAttr.name).thenReturn("doubleAttr")
        when(doubleAttr.EAttributeType).thenReturn(EcorePackage.Literals.EDOUBLE)
        when(stringAttr.name).thenReturn("stringAttr")
        when(stringAttr.EAttributeType).thenReturn(EcorePackage.Literals.ESTRING)
        when(enumAttr.name).thenReturn("enumAttr")
        when(enumAttr.EAttributeType).thenReturn(enumMock)
        when(wrappingAttr.name).thenReturn("wrappingAttr")
        when(wrappingAttr.EAttributeType).thenReturn(ownDataTypeMock)

        val classMock = mock(EClass)
        when(classMock.name).thenReturn("TestClass")
        when(classMock.EPackage).thenReturn(ePackageMock)
        when(classMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[
            booleanAttr, intAttr, longAttr, floatAttr, doubleAttr, stringAttr, enumAttr, wrappingAttr
        ]))

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[classMock]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator

        // when
        val String idl = generator.idlTypeDefinition(classMock, genPackageMock.basePackage, genModelMock).toString

        // then
        val String expected = '''
        @namespace("com.base.package.leaf.avro")
        record TestClass {
            boolean booleanAttr;
            int intAttr;
            long longAttr;
            float floatAttr;
            double doubleAttr;
            string stringAttr;
            com.base.package.leaf.avro.MyEnum enumAttr;
            string wrappingAttr;
        }
        '''
        assertThat(idl).isEqualTo(expected)
    }
    
    @Test
    def void shouldRecognizeImplementation() {
    	// given
    	val intrfaceMock = mock(EClass)
        when(intrfaceMock.name).thenReturn("MyInterface")
        when(intrfaceMock.interface).thenReturn(true)
        when(intrfaceMock.abstract).thenReturn(true)

        val impl1 = mock(EClass)
        when(impl1.name).thenReturn("MyInterfaceImpl1")
        when(intrfaceMock.isSuperTypeOf(impl1)).thenReturn(true)
        
        val generator = new IDLGenerator
        
        // when
		val isInterface = generator.isImplementation(impl1, intrfaceMock)
		
		// then
		assertThat(isInterface).isTrue        
    }
    
    @Test
    def void shouldNotRecognizeImplementation() {
    	// given
    	val intrfaceMock = mock(EClass)
        when(intrfaceMock.name).thenReturn("MyInterface")
        when(intrfaceMock.interface).thenReturn(true)
        when(intrfaceMock.abstract).thenReturn(true)

        val impl1 = mock(EClass)
        when(impl1.name).thenReturn("MyInterfaceImpl1")
        when(intrfaceMock.isSuperTypeOf(impl1)).thenReturn(false)
        
        val generator = new IDLGenerator
        
        // when
		val isInterface = generator.isImplementation(impl1, intrfaceMock)
		
		// then
		assertThat(isInterface).isFalse        
    }

    @Test
    def void shouldGenerateRecordReferencesCorrectly() {
        // given
        val booleanAttr = mock(EAttribute)
        val intAttr = mock(EAttribute)
        val longAttr = mock(EAttribute)
        val floatAttr = mock(EAttribute)
        val doubleAttr = mock(EAttribute)
        val stringAttr = mock(EAttribute)
        val wrappingAttr = mock(EAttribute)

        val ownDataTypeMock = mock(EDataType)
        when(ownDataTypeMock.instanceClass).thenReturn(Date)

        when(booleanAttr.name).thenReturn("booleanAttr")
        when(booleanAttr.EAttributeType).thenReturn(EcorePackage.Literals.EBOOLEAN)
        when(intAttr.name).thenReturn("intAttr")
        when(intAttr.EAttributeType).thenReturn(EcorePackage.Literals.EINT)
        when(longAttr.name).thenReturn("longAttr")
        when(longAttr.EAttributeType).thenReturn(EcorePackage.Literals.ELONG)
        when(floatAttr.name).thenReturn("floatAttr")
        when(floatAttr.EAttributeType).thenReturn(EcorePackage.Literals.EFLOAT)
        when(doubleAttr.name).thenReturn("doubleAttr")
        when(doubleAttr.EAttributeType).thenReturn(EcorePackage.Literals.EDOUBLE)
        when(stringAttr.name).thenReturn("stringAttr")
        when(stringAttr.EAttributeType).thenReturn(EcorePackage.Literals.ESTRING)
        when(wrappingAttr.name).thenReturn("wrappingAttr")
        when(wrappingAttr.EAttributeType).thenReturn(ownDataTypeMock)

        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val classMock = mock(EClass)
        when(classMock.name).thenReturn("TestClass")
        when(classMock.EPackage).thenReturn(ePackageMock)
        when(classMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[
            booleanAttr, intAttr, longAttr, floatAttr, doubleAttr, stringAttr, wrappingAttr
        ]))

        val ref = mock(EReference)
        when(ref.name).thenReturn("ref")
        when(ref.EReferenceType).thenReturn(classMock)

        val otherPackageMock = mock(EPackage)
        when(otherPackageMock.name).thenReturn("other")

        val containerClassMock = mock(EClass)
        when(containerClassMock.name).thenReturn("ContainerClass")
        when(containerClassMock.EPackage).thenReturn(otherPackageMock)
        when(containerClassMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[ref]))

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[classMock, containerClassMock]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator

        // when
        val String idl = generator.idlTypeDefinition(containerClassMock, genPackageMock.basePackage, genModelMock).toString

        // then
        val String expected = '''
        @namespace("com.base.package.other.avro")
        record ContainerClass {
            com.base.package.leaf.avro.TestClass ref;
        }
        '''
        assertThat(idl).isEqualTo(expected)
    }
    
    @Test
    def void shouldGenerateListTypesCorrectly() {
        // given
        val listOfStrings = mock(EAttribute)
        when(listOfStrings.name).thenReturn("listOfStrings")
        when(listOfStrings.upperBound).thenReturn(-1)
        when(listOfStrings.EAttributeType).thenReturn(EcorePackage.Literals.ESTRING)

        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val classMock = mock(EClass)
        when(classMock.name).thenReturn("TestClass")
        when(classMock.EPackage).thenReturn(ePackageMock)
        when(classMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[listOfStrings]))

        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[classMock]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator
        
        // when
        val String idl = generator.idlTypeDefinition(classMock, genPackageMock.basePackage, genModelMock).toString
        
        // then
        val expected = '''
        @namespace("com.base.package.leaf.avro")
        record TestClass {
            array<string> listOfStrings;
        }
        '''
        assertThat(idl).isEqualTo(expected)
    }

    @Test
    def void shouldGenerateCompleteProtocol() {
        // given
        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val booleanAttr = mock(EAttribute)
        val intAttr = mock(EAttribute)
        val longAttr = mock(EAttribute)
        val floatAttr = mock(EAttribute)
        val doubleAttr = mock(EAttribute)
        val stringAttr = mock(EAttribute)
        val enumAttr = mock(EAttribute)
        val wrappingAttr = mock(EAttribute)

        val ownDataTypeMock = mock(EDataType)
        when(ownDataTypeMock.instanceClass).thenReturn(Date)

        when(booleanAttr.name).thenReturn("booleanAttr")
        when(booleanAttr.EAttributeType).thenReturn(EcorePackage.Literals.EBOOLEAN)
        when(intAttr.name).thenReturn("intAttr")
        when(intAttr.EAttributeType).thenReturn(EcorePackage.Literals.EINT)
        when(longAttr.name).thenReturn("longAttr")
        when(longAttr.EAttributeType).thenReturn(EcorePackage.Literals.ELONG)
        when(floatAttr.name).thenReturn("floatAttr")
        when(floatAttr.EAttributeType).thenReturn(EcorePackage.Literals.EFLOAT)
        when(doubleAttr.name).thenReturn("doubleAttr")
        when(doubleAttr.EAttributeType).thenReturn(EcorePackage.Literals.EDOUBLE)
        when(stringAttr.name).thenReturn("stringAttr")
        when(stringAttr.EAttributeType).thenReturn(EcorePackage.Literals.ESTRING)
        when(wrappingAttr.name).thenReturn("wrappingAttr")
        when(wrappingAttr.EAttributeType).thenReturn(ownDataTypeMock)

        val classMock = mock(EClass)
        when(classMock.name).thenReturn("TestClass")
        when(classMock.interface).thenReturn(false)
        when(classMock.EPackage).thenReturn(ePackageMock)
        when(classMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[
            booleanAttr, intAttr, longAttr, floatAttr, doubleAttr, stringAttr, enumAttr, wrappingAttr
        ]))

        val literalMock1 = mock(EEnumLiteral)
        val literalMock2 = mock(EEnumLiteral)
        val literalMock3 = mock(EEnumLiteral)

        when(literalMock1.name).thenReturn("Literal1")
        when(literalMock2.name).thenReturn("Literal2")
        when(literalMock3.name).thenReturn("Literal3")

        val enumMock = mock(EEnum)
        when(enumMock.name).thenReturn("TestEnum")
        when(enumMock.ELiterals).thenReturn(new BasicEList(#[literalMock1, literalMock2, literalMock3]))
        when(enumMock.EPackage).thenReturn(ePackageMock)

        when(enumAttr.name).thenReturn("enumAttr")
        when(enumAttr.EAttributeType).thenReturn(enumMock)

        val intrfaceMock = mock(EClass)
        when(intrfaceMock.name).thenReturn("MyInterface")
        when(intrfaceMock.abstract).thenReturn(true)
        when(intrfaceMock.interface).thenReturn(true)
        when(intrfaceMock.EPackage).thenReturn(ePackageMock);

        val impl1 = mock(EClass)
        when(impl1.name).thenReturn("MyInterfaceImpl1")
        when(impl1.EPackage).thenReturn(ePackageMock)
        when(intrfaceMock.isSuperTypeOf(impl1)).thenReturn(true)
        when(impl1.EAllStructuralFeatures).thenReturn(new BasicEList)

        val impl2 = mock(EClass)
        when(impl2.name).thenReturn("MyInterfaceImpl2")
        when(impl2.EPackage).thenReturn(ePackageMock)
        when(intrfaceMock.isSuperTypeOf(impl2)).thenReturn(true)
        when(impl2.EAllStructuralFeatures).thenReturn(new BasicEList)

        val ref = mock(EReference)
        when(ref.name).thenReturn("ref")
        when(ref.upperBound).thenReturn(5)
        when(ref.EReferenceType).thenReturn(classMock)

        val union = mock(EReference)
        when(union.name).thenReturn("uRef")
        when(union.EReferenceType).thenReturn(intrfaceMock)

        val otherPackageMock = mock(EPackage)
        when(otherPackageMock.name).thenReturn("other")

        val containerClassMock = mock(EClass)
        when(containerClassMock.name).thenReturn("ContainerClass")
        when(containerClassMock.EPackage).thenReturn(otherPackageMock)
        when(containerClassMock.EAllStructuralFeatures).thenReturn(new BasicEList(#[ref, union]))
        
        val ecorePackageMock = mock(EcorePackage)
        when(ecorePackageMock.EClassifiers).thenReturn(new BasicEList(#[ownDataTypeMock, classMock, containerClassMock, enumMock, intrfaceMock, impl1, impl2]))

        val genPackageMock = mock(GenPackage)
        when(genPackageMock.basePackage).thenReturn("com.base.package")
        when(genPackageMock.getEcorePackage).thenReturn(ecorePackageMock)

        val genModelMock = mock(GenModel)
        when(genModelMock.modelName).thenReturn("TestModel")
        when(genModelMock.genPackages).thenReturn(new BasicEList(#[genPackageMock]))

        val generator = new IDLGenerator

        // when
        val idl = generator.generateIdl(genModelMock)
        val expected = '''
        @namespace("com.base.package")
        protocol TestModel {
            @namespace("com.base.package.leaf.avro")
            record TestClass {
                boolean booleanAttr;
                int intAttr;
                long longAttr;
                float floatAttr;
                double doubleAttr;
                string stringAttr;
                com.base.package.leaf.avro.TestEnum enumAttr;
                string wrappingAttr;
            }
            @namespace("com.base.package.other.avro")
            record ContainerClass {
                array<com.base.package.leaf.avro.TestClass> ref;
                union { com.base.package.leaf.avro.MyInterfaceImpl1, com.base.package.leaf.avro.MyInterfaceImpl2 } uRef;
            }
            @namespace("com.base.package.leaf.avro")
            enum TestEnum {
                Literal1, Literal2, Literal3
            }
            @namespace("com.base.package.leaf.avro")
            record MyInterfaceImpl1 {
            }
            @namespace("com.base.package.leaf.avro")
            record MyInterfaceImpl2 {
            }
        }
        '''

        // then
        assertThat(idl).isEqualTo(expected)
    }
}