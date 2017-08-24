package com.ottogroup.emfavro

import org.apache.avro.Protocol
import org.apache.avro.Schema
import org.apache.avro.generic.GenericData
import org.apache.avro.generic.GenericRecord
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EcoreFactory
import org.eclipse.emf.ecore.EcorePackage
import org.junit.Test

import static org.assertj.core.api.Assertions.assertThat
import static org.assertj.core.api.Assertions.assertThatExceptionOfType
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.when

class EObject2RecordTest {
    @Test
    def void shouldThrowIfMissingSchemaInProtocol() {
        // given
        val eClass = mock(EClass)
        when(eClass.instanceTypeName).thenReturn("test.MissingClass")

        val protocol = mock(Protocol)
        when(protocol.getType("test.avro.Class")).thenReturn(mock(Schema))
        when(protocol.getType("test.avro.MissingClass")).thenReturn(null)

        // when // then
        assertThatExceptionOfType(SchemaNotFoundException)
            .isThrownBy[EObject2Record.findAvroSchema(eClass, protocol)]
    }

    @Test
    def void shouldFindSchemaInProtocol() {
        // given
        val eClass = mock(EClass)
        when(eClass.instanceTypeName).thenReturn("test.Class")

        val schema = mock(Schema)
        when(schema.namespace).thenReturn("test.avro")
        when(schema.name).thenReturn("Class")

        val protocol = mock(Protocol)
        when(protocol.getType("test.avro.Class")).thenReturn(schema)
        when(protocol.getType("test.avro.MissingClass")).thenReturn(null)

        // when
        val foundSchema = EObject2Record.findAvroSchema(eClass, protocol)

        // then
        assertThat(foundSchema).isNotNull.isSameAs(schema)
    }

    @Test
    def void shouldConvertPrimitesCorrectly() {
        // given
        val eClass = EcoreFactory.eINSTANCE.createEClass
        eClass.name = "Primitives"
        eClass.instanceTypeName = "test.Primitives"

        val booleanAttr = EcoreFactory.eINSTANCE.createEAttribute
        booleanAttr.name = "booleanAttr"
        booleanAttr.EType = EcorePackage.eINSTANCE.EBoolean
        val intAttr = EcoreFactory.eINSTANCE.createEAttribute
        intAttr.name = "intAttr"
        intAttr.EType = EcorePackage.eINSTANCE.EInt
        val longAttr = EcoreFactory.eINSTANCE.createEAttribute
        longAttr.name = "longAttr"
        longAttr.EType = EcorePackage.eINSTANCE.ELong
        val floatAttr = EcoreFactory.eINSTANCE.createEAttribute
        floatAttr.name = "floatAttr"
        floatAttr.EType = EcorePackage.eINSTANCE.EFloat
        val doubleAttr = EcoreFactory.eINSTANCE.createEAttribute
        doubleAttr.name = "doubleAttr"
        doubleAttr.EType = EcorePackage.eINSTANCE.EDouble
        val stringAttr = EcoreFactory.eINSTANCE.createEAttribute
        stringAttr.name = "stringAttr"
        stringAttr.EType = EcorePackage.eINSTANCE.EString

        eClass.EStructuralFeatures.addAll(#[booleanAttr, intAttr, longAttr, floatAttr, doubleAttr, stringAttr])

        val ePackage = EcoreFactory.eINSTANCE.createEPackage
        ePackage.name = "test"
        ePackage.nsPrefix = "test"
        ePackage.nsURI = "http://ottogroup.com/test"

        ePackage.EClassifiers.add(eClass)

        val eObject = ePackage.EFactoryInstance.create(eClass)
        eObject.eSet(booleanAttr, true)
        eObject.eSet(intAttr, 42)
        eObject.eSet(longAttr, 1337L)
        eObject.eSet(floatAttr, 3.14f)
        eObject.eSet(doubleAttr, 3.14d)
        eObject.eSet(stringAttr, "foo")

        val schema = new Schema.Parser().parse('''{
            "namespace": "test.avro",
            "type": "record",
            "name": "Primitives",
            "fields": [
                {
                    "name": "booleanAttr",
                    "type": "boolean"
                },
                {
                    "name": "intAttr",
                    "type": "int"
                },
                {
                    "name": "longAttr",
                    "type": "long"
                },
                {
                    "name": "floatAttr",
                    "type": "float"
                },
                {
                    "name": "doubleAttr",
                    "type": "float"
                },
                {
                    "name": "stringAttr",
                    "type": "string"
                }
            ]
        }''')

        val protocol = mock(Protocol)
        when(protocol.getType("test.avro.Primitives")).thenReturn(schema)

        // when
        val record = EObject2Record.convert(eObject, protocol)

        // then
        assertThat(record).isNotNull
        assertThat(record.get("booleanAttr")).isEqualTo(true)
        assertThat(record.get("intAttr")).isEqualTo(42)
        assertThat(record.get("longAttr")).isEqualTo(1337L)
        assertThat(record.get("floatAttr")).isEqualTo(3.14f)
        assertThat(record.get("doubleAttr")).isEqualTo(3.14d)
        assertThat(record.get("stringAttr")).isEqualTo("foo")
    }

    @Test
    def void shouldConvertEnumCorrectly() {
        // given
        val eLiteral = EcoreFactory.eINSTANCE.createEEnumLiteral
        eLiteral.name = "vim"

        val eEnum = EcoreFactory.eINSTANCE.createEEnum
        eEnum.name = "AwesomeEditors"
        eEnum.instanceTypeName = "test.AwesomeEditors"
        eEnum.ELiterals.add(eLiteral)

        val eClass = EcoreFactory.eINSTANCE.createEClass
        eClass.name = "Developer"
        eClass.instanceTypeName = "test.Developer"

        val enumAttr = EcoreFactory.eINSTANCE.createEAttribute
        enumAttr.name = "favoriteEditor"
        enumAttr.EType = eEnum

        eClass.EStructuralFeatures.add(enumAttr)

        val ePackage = EcoreFactory.eINSTANCE.createEPackage
        ePackage.name = "test"
        ePackage.nsPrefix = "test"
        ePackage.nsURI = "http://ottogroup.com/test"

        ePackage.EClassifiers.add(eClass)

        val eObject = ePackage.EFactoryInstance.create(eClass)
        eObject.eSet(enumAttr, eLiteral)

        val parser = new Schema.Parser()
        val editorsSchema = parser.parse('''{
            "namespace": "test.avro",
            "type": "enum",
            "name": "AwesomeEditors",
            "symbols": ["vim"]
        }''')

        val developerSchema = parser.parse('''{
            "namespace": "test.avro",
            "type": "record",
            "name": "Developer",
            "fields": [
                {
                    "name": "favoriteEditor",
                    "type": "test.avro.AwesomeEditors"
                }
            ]
        }''')

        val protocol = mock(Protocol)
        when(protocol.getType("test.avro.Developer")).thenReturn(developerSchema)
        when(protocol.getType("test.avro.AwesomeEditors")).thenReturn(editorsSchema)

        // when
        val record = EObject2Record.convert(eObject, protocol)
        
        // then
        assertThat(record).isNotNull
        val vimEnumSymbol = new GenericData().createEnum("vim", editorsSchema)
        assertThat(record.get("favoriteEditor")).isEqualTo(vimEnumSymbol)
    }

    @Test
    def void shouldCreateReferenceCorrectly() {
        // given
        val referencedClass = EcoreFactory.eINSTANCE.createEClass
        referencedClass.name = "ReferencedClass"
        referencedClass.instanceTypeName = "test.ReferencedClass"

        val nameAttr = EcoreFactory.eINSTANCE.createEAttribute
        nameAttr.name = "name"
        nameAttr.EType = EcorePackage.eINSTANCE.EString
        referencedClass.EStructuralFeatures.add(nameAttr)

        val referencingClass = EcoreFactory.eINSTANCE.createEClass
        referencingClass.name = "ReferencingClass"
        referencingClass.instanceTypeName = "test.ReferencingClass"

        val reference = EcoreFactory.eINSTANCE.createEReference
        reference.name = "reference"
        reference.containment = true
        reference.EType = referencedClass
        referencingClass.EStructuralFeatures.add(reference)

        val ePackage = EcoreFactory.eINSTANCE.createEPackage
        ePackage.name = "test"
        ePackage.nsPrefix = "test"
        ePackage.nsURI = "http://ottogroup.com/test"

        ePackage.EClassifiers.addAll(#[referencedClass, referencingClass])

        val referencedEObject = ePackage.EFactoryInstance.create(referencedClass)
        referencedEObject.eSet(nameAttr, "foo")
        val referencingEObject = ePackage.EFactoryInstance.create(referencingClass)
        referencingEObject.eSet(reference, referencedEObject)

        val parser = new Schema.Parser()
        val referencedSchema = parser.parse('''{
            "namespace": "test.avro",
            "type": "record",
            "name": "ReferencedClass",
            "fields": [
                {
                    "name": "name",
                    "type": "string"
                }
            ]
        }''')

        val referencingSchema = parser.parse('''{
            "namespace": "test.avro",
            "type": "record",
            "name": "ReferencingClass",
            "fields": [
                {
                    "name": "reference",
                    "type": "test.avro.ReferencedClass"
                }
            ]
        }''')

        val protocol = mock(Protocol)
        when(protocol.getType("test.avro.ReferencedClass")).thenReturn(referencedSchema)
        when(protocol.getType("test.avro.ReferencingClass")).thenReturn(referencingSchema)
        
        // when
        val record = EObject2Record.convert(referencingEObject, protocol)
        
        // then
        assertThat(record).isNotNull
        val referencedRecord = record.get("reference") as GenericRecord
        assertThat(referencedRecord).isNotNull
        assertThat(referencedRecord.get("name")).isEqualTo("foo")
    }
}