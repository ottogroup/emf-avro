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
import static org.assertj.core.api.Assertions.tuple
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.when

import org.apache.avro.Schema

class Ecore2AvroTest {

    @Test
    def void shouldNotAcceptMissingGenPackage() {
        // given
        val genModelMock = mock(GenModel)
        when(genModelMock.genPackages).thenReturn(new BasicEList)
        when(genModelMock.modelName).thenReturn("Test Model")

        // when // then
        assertThatExceptionOfType(IllegalArgumentException)
            .isThrownBy([Ecore2Avro.convert(genModelMock)])
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

        // when
        val classifiersToGenerate = Ecore2Avro.getClassifiersToGenerate(genPackage)
        
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

        // when
        val classifiersToGenerate = Ecore2Avro.getClassifiersToGenerate(genPackage)
        
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

        // when
        val schema = Ecore2Avro.toAvroSchema(enumMock, genPackageMock.basePackage, genModelMock)

        // then
        assertThat(schema).isNotNull
        assertThat(schema.type).isEqualTo(Schema.Type.ENUM)
        assertThat(schema.getEnumSymbols).containsExactly("Literal1", "Literal2", "Literal3")
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

        // when // then
        val booleanType = Ecore2Avro.toAvroField(booleanAttr, null, null).schema.type
        val intType = Ecore2Avro.toAvroField(intAttr, null, null).schema.type
        val longType = Ecore2Avro.toAvroField(longAttr, null, null).schema.type
        val floatType = Ecore2Avro.toAvroField(floatAttr, null, null).schema.type
        val doubleType = Ecore2Avro.toAvroField(doubleAttr, null, null).schema.type
        val stringType = Ecore2Avro.toAvroField(stringAttr, null, null).schema.type
        val wrappingType = Ecore2Avro.toAvroField(wrappingAttr, null, null).schema.type

        assertThat(booleanType).isEqualTo(Schema.Type.BOOLEAN)
        assertThat(intType).isEqualTo(Schema.Type.INT)
        assertThat(longType).isEqualTo(Schema.Type.LONG)
        assertThat(floatType).isEqualTo(Schema.Type.FLOAT)
        assertThat(doubleType).isEqualTo(Schema.Type.DOUBLE)
        assertThat(stringType).isEqualTo(Schema.Type.STRING)
        assertThat(wrappingType).isEqualTo(Schema.Type.STRING)
    }

    @Test
    def void shouldFindAvroTypeForClass() {
        // given
        val ePackageMock = mock(EPackage)
        when(ePackageMock.name).thenReturn("leaf")

        val classMock = mock(EClass)
        when(classMock.name).thenReturn("TestClass")
        when(classMock.EPackage).thenReturn(ePackageMock)
        when(classMock.EAllStructuralFeatures).thenReturn(new BasicEList)

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

        // when
        val referencedSchema = Ecore2Avro.toAvroField(ref, genPackageMock.basePackage, genModelMock).schema
        
        // then
        val testClassSchema = Ecore2Avro.toAvroSchema(classMock, genPackageMock.basePackage, genModelMock)
		assertThat(referencedSchema).isEqualTo(testClassSchema)
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
        when(impl1.EAllStructuralFeatures).thenReturn(new BasicEList)
        when(intrfaceMock.isSuperTypeOf(impl1)).thenReturn(true)

        val impl2 = mock(EClass)
        when(impl2.name).thenReturn("MyInterfaceImpl2")
        when(impl2.EPackage).thenReturn(ePackageMock)
        when(impl2.EAllStructuralFeatures).thenReturn(new BasicEList)
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

        // when
        val unionField = Ecore2Avro.toAvroField(ref, genPackageMock.basePackage, genModelMock)
        
        // then
        assertThat(unionField.name).isEqualTo("ref")
        assertThat(unionField.schema.type).isEqualTo(Schema.Type.UNION)
        val impl1Schema = Ecore2Avro.toAvroSchema(impl1, genPackageMock.basePackage, genModelMock)
        val impl2Schema = Ecore2Avro.toAvroSchema(impl2, genPackageMock.basePackage, genModelMock)
        assertThat(unionField.schema.types).containsExactly(impl1Schema, impl2Schema)
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

        // when
        val impls = Ecore2Avro.findImplementations(intrfaceMock, genModelMock)
        
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
        when(enumMock.ELiterals).thenReturn(new BasicEList)

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

        // when
        val schema = Ecore2Avro.toAvroSchema(classMock, genPackageMock.basePackage, genModelMock)

        // then
        assertThat(schema).isNotNull
        assertThat(schema.namespace).isEqualTo("com.base.package.leaf.avro")
        assertThat(schema.type).isEqualTo(Schema.Type.RECORD)
        assertThat(schema.name).isEqualTo("TestClass")
        assertThat(schema.getFields)
            .hasSize(8)
            .extracting("name", "schema.type")
            .contains(
                tuple("booleanAttr", Schema.Type.BOOLEAN),
                tuple("intAttr", Schema.Type.INT),
                tuple("longAttr", Schema.Type.LONG),
                tuple("floatAttr", Schema.Type.FLOAT),
                tuple("doubleAttr", Schema.Type.DOUBLE),
                tuple("stringAttr", Schema.Type.STRING),
                tuple("enumAttr", Schema.Type.ENUM),
                tuple("wrappingAttr", Schema.Type.STRING))
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
        
        // when
		val isInterface = Ecore2Avro.isImplementation(impl1, intrfaceMock)
		
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
        
        // when
		val isInterface = Ecore2Avro.isImplementation(impl1, intrfaceMock)
		
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

        // when
        val schema = Ecore2Avro.toAvroSchema(containerClassMock, genPackageMock.basePackage, genModelMock)

        // then
        assertThat(schema).isNotNull
        assertThat(schema.namespace).isEqualTo("com.base.package.other.avro")
        assertThat(schema.name).isEqualTo("ContainerClass")
        assertThat(schema.fields).hasSize(1)
        assertThat(schema.getField("ref")).isNotNull
        assertThat(schema.getField("ref").schema.type).isEqualTo(Schema.Type.RECORD)
        val testClassSchema = Ecore2Avro.toAvroSchema(classMock, genPackageMock.basePackage, genModelMock)
        assertThat(schema.getField("ref").schema).isEqualTo(testClassSchema)
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

        // when
        val schema = Ecore2Avro.toAvroSchema(classMock, genPackageMock.basePackage, genModelMock)

        // then
        assertThat(schema).isNotNull
        assertThat(schema.namespace).isEqualTo("com.base.package.leaf.avro")
        assertThat(schema.name).isEqualTo("TestClass")
        assertThat(schema.getFields).hasSize(1)
        val listField = schema.getField("listOfStrings")
        assertThat(listField).isNotNull
        assertThat(listField.name).isEqualTo("listOfStrings")
        assertThat(listField.schema.type).isEqualTo(Schema.Type.ARRAY)
        assertThat(listField.schema.elementType).isEqualTo(Schema.create(Schema.Type.STRING))
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

        // when
        val protocol = Ecore2Avro.convert(genModelMock)

        // then
        assertThat(protocol).isNotNull
        assertThat(protocol.namespace).isEqualTo("com.base.package")
        assertThat(protocol.name).isEqualTo("TestModel")
        assertThat(protocol.types).hasSize(5)

        val testClassSchema = protocol.getType("com.base.package.leaf.avro.TestClass")
        assertThat(testClassSchema).isNotNull
        assertThat(testClassSchema.type).isEqualTo(Schema.Type.RECORD)
        assertThat(testClassSchema.getFields)
            .hasSize(8)
            .extracting("name", "schema.type")
            .contains(
                tuple("booleanAttr", Schema.Type.BOOLEAN),
                tuple("intAttr", Schema.Type.INT),
                tuple("longAttr", Schema.Type.LONG),
                tuple("floatAttr", Schema.Type.FLOAT),
                tuple("doubleAttr", Schema.Type.DOUBLE),
                tuple("stringAttr", Schema.Type.STRING),
                tuple("enumAttr", Schema.Type.ENUM),
                tuple("wrappingAttr", Schema.Type.STRING))

        val containerClassSchema = protocol.getType("com.base.package.other.avro.ContainerClass")
        assertThat(containerClassSchema).isNotNull
        assertThat(containerClassSchema.type).isEqualTo(Schema.Type.RECORD)
        assertThat(containerClassSchema.fields).hasSize(2)
        val refField = containerClassSchema.getField("ref")
        assertThat(refField.schema.type).isEqualTo(Schema.Type.ARRAY)
        assertThat(refField.schema.elementType).isEqualTo(testClassSchema)
        val unionField = containerClassSchema.getField("uRef")
        assertThat(unionField.schema.type).isEqualTo(Schema.Type.UNION)

        val testEnumSchema = protocol.getType("com.base.package.leaf.avro.TestEnum")
        assertThat(testEnumSchema.type).isEqualTo(Schema.Type.ENUM)
        assertThat(testEnumSchema.enumSymbols).containsExactly("Literal1", "Literal2", "Literal3")
        assertThat(testClassSchema.getField("enumAttr").schema).isEqualTo(testEnumSchema)

        val impl1Schema = protocol.getType("com.base.package.leaf.avro.MyInterfaceImpl1")
        assertThat(impl1Schema.type).isEqualTo(Schema.Type.RECORD)

        val impl2Schema = protocol.getType("com.base.package.leaf.avro.MyInterfaceImpl2")
        assertThat(impl2Schema.type).isEqualTo(Schema.Type.RECORD)

        assertThat(unionField.schema.types).containsExactly(impl1Schema, impl2Schema)
    }
}