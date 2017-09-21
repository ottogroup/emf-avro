package com.ottogroup.emfavro

import java.util.Date

import org.apache.avro.generic.GenericData.EnumSymbol
import org.apache.avro.generic.GenericRecord
import org.apache.avro.{Protocol, Schema}
import org.eclipse.emf.ecore.{EcoreFactory, EcorePackage}
import org.scalatest.{FlatSpec, GivenWhenThen, Matchers}

import scala.collection.JavaConverters._

class EObject2RecordSpec extends FlatSpec with Matchers with GivenWhenThen {
  "The EObject2Record converter" should "throw an IllegalArgumentException for a null parameter" in {
    Given("an empty protocol and sample EObject")
    val protocol = new Protocol(null, null)
    val eobject = EcoreFactory.eINSTANCE

    When("null is given into convert() for either parameter")
    Then("it should throw an IllegalArgumentException")
    an [IllegalArgumentException] should be thrownBy EObject2Record.convert(null, new Protocol(null, null))
    an [IllegalArgumentException] should be thrownBy EObject2Record.convert(eobject, null)
  }

  it should "throw a SchemaNotFoundException if a schema cannot be found in the protocol" in {
    Given("an EClass and an empty Avro protocol")
    val eClass = EcoreFactory.eINSTANCE.createEClass()
    eClass.setName("MissingClass")

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("test")
    ePackage.setNsPrefix("test")
    ePackage.setNsURI("http://www.ottogroup.com/test")
    ePackage.getEClassifiers.add(eClass)

    val protocol = new Protocol("Test", "com.base.package")

    When("the corresponding Avro schema is looked up in the protocol")
    Then("it should throw an SchemaNotFoundException")
    a [SchemaNotFoundException] should be thrownBy EObject2Record.findAvroSchema(eClass, protocol)
  }

  it should "find the corresponding schema for an EClass in an Avro protocol" in {
    Given("a class with a corresponding schema in the protocol")
    val eClass = EcoreFactory.eINSTANCE.createEClass()
    eClass.setName("AClass")

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("test")
    ePackage.setNsPrefix("test")
    ePackage.setNsURI("http://www.ottogroup.com/test")
    ePackage.getEClassifiers.add(eClass)

    val protocol = new Protocol("Test", "com.base.package")
    val schema = Schema.createRecord("AClass", null, "com.base.package.test.avro", false)
    protocol.setTypes(List(schema).asJava)

    When("the corresponding Avro schema is looked up in the protocol")
    val lookedUpSchema = EObject2Record.findAvroSchema(eClass, protocol)

    Then("it should return the schema")
    lookedUpSchema should be(schema)
  }

  it should "convert an EObject containing several primitives correctly" in {
    Given("an EObject containing several primitives")
    val booleanAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val intAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val longAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val floatAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val doubleAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val stringAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val wrappingAttr = EcoreFactory.eINSTANCE.createEAttribute()

    val dateDataType = EcoreFactory.eINSTANCE.createEDataType()
    dateDataType.setInstanceClass(classOf[Date])

    booleanAttr.setName("booleanAttr")
    booleanAttr.setEType(EcorePackage.Literals.EBOOLEAN)
    intAttr.setName("intAttr")
    intAttr.setEType(EcorePackage.Literals.EINT)
    longAttr.setName("longAttr")
    longAttr.setEType(EcorePackage.Literals.ELONG)
    floatAttr.setName("floatAttr")
    floatAttr.setEType(EcorePackage.Literals.EFLOAT)
    doubleAttr.setName("doubleAttr")
    doubleAttr.setEType(EcorePackage.Literals.EDOUBLE)
    stringAttr.setName("stringAttr")
    stringAttr.setEType(EcorePackage.Literals.ESTRING)
    wrappingAttr.setName("wrappingAttr")
    wrappingAttr.setEType(dateDataType)

    val eClass = EcoreFactory.eINSTANCE.createEClass()
    eClass.setName("Primitives")
    eClass.getEStructuralFeatures.addAll(List(booleanAttr, intAttr, longAttr, floatAttr,
      doubleAttr, stringAttr, wrappingAttr).asJava)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("test")
    ePackage.getEClassifiers.add(eClass)

    val eObject = ePackage.getEFactoryInstance.create(eClass)
    eObject.eSet(booleanAttr, true)
    eObject.eSet(intAttr, 42)
    eObject.eSet(longAttr, 1337L)
    eObject.eSet(floatAttr, 3.14f)
    eObject.eSet(doubleAttr, 3.14d)
    eObject.eSet(stringAttr, "foo")
    eObject.eSet(wrappingAttr, new Date)

    val schema = new Schema.Parser().parse("""{
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
        "name": "wrappingAttr",
        "type": "string"
      },
      {
        "name": "stringAttr",
        "type": "string"
      }
      ]
    }""")

    val protocol = new Protocol("Test", null)
    protocol.setTypes(List(schema).asJava)

    When("it is converted")
    val record = EObject2Record.convert(eObject, protocol)

    Then("all primitives should have the correct value set in the record")
    record shouldNot be(null)
    record.get("booleanAttr") shouldEqual true
    record.get("intAttr") shouldEqual 42
    record.get("longAttr") shouldEqual 1337L
    record.get("floatAttr") shouldEqual 3.14f
    record.get("doubleAttr") shouldEqual 3.14d
    record.get("stringAttr") shouldEqual "foo"
    record.get("wrappingAttr") shouldEqual eObject.eGet(wrappingAttr).toString
  }

  it should "convert an EObject containing an enum attribute correctly" in {
    Given("an EObject containing an enum attribute")
    val literal1 = EcoreFactory.eINSTANCE.createEEnumLiteral()
    literal1.setName("Literal1")
    val literal2 = EcoreFactory.eINSTANCE.createEEnumLiteral()
    literal2.setName("Literal2")
    val literal3 = EcoreFactory.eINSTANCE.createEEnumLiteral()
    literal3.setName("Literal3")

    val enum = EcoreFactory.eINSTANCE.createEEnum()
    enum.setName("TestEnum")
    enum.getELiterals.addAll(Seq(literal1, literal2, literal3).asJava)

    val enumAttr = EcoreFactory.eINSTANCE.createEAttribute()
    enumAttr.setName("enumAttr")
    enumAttr.setEType(enum)

    val eClass = EcoreFactory.eINSTANCE.createEClass()
    eClass.setName("AClass")
    eClass.getEStructuralFeatures.add(enumAttr)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("test")
    ePackage.getEClassifiers.add(eClass)
    ePackage.getEClassifiers.add(enum)

    val eObject = ePackage.getEFactoryInstance.create(eClass)
    eObject.eSet(enumAttr, literal2)

    val parser = new Schema.Parser()
    val enumSchema = parser.parse("""{
      "namespace": "test.avro",
      "type": "enum",
      "name": "TestEnum",
      "symbols": ["Literal1", "Literal2", "Literal3"]
    }""")

    val classSchema = parser.parse("""{
      "namespace": "test.avro",
      "type": "record",
      "name": "AClass",
      "fields": [
      {
        "name": "enumAttr",
        "type": "test.avro.TestEnum"
      }
      ]
    }""")

    val protocol = new Protocol("Test", null)
    protocol.setTypes(List(enumSchema, classSchema).asJava)

    When("it is converted")
    val record = EObject2Record.convert(eObject, protocol)

    Then("the enumAttr should have the correct literal set")
    record shouldNot be(null)
    record.get("enumAttr").asInstanceOf[EnumSymbol].toString shouldEqual "Literal2"
  }

  it should "convert an EObject containing a reference to another EObject correctly" in {
    Given("an EObject containing a reference to another EObject")
    val intAttr = EcoreFactory.eINSTANCE.createEAttribute()
    intAttr.setName("intAttr")
    intAttr.setEType(EcorePackage.Literals.EINT)

    val anotherClass = EcoreFactory.eINSTANCE.createEClass()
    anotherClass.setName("AnotherClass")
    anotherClass.getEStructuralFeatures.add(intAttr)

    val reference = EcoreFactory.eINSTANCE.createEReference()
    reference.setName("reference")
    reference.setEType(anotherClass)

    val aClass = EcoreFactory.eINSTANCE.createEClass()
    aClass.setName("AClass")
    aClass.getEStructuralFeatures.add(reference)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("test")
    ePackage.getEClassifiers.add(anotherClass)
    ePackage.getEClassifiers.add(aClass)

    val anObject = ePackage.getEFactoryInstance.create(aClass)
    val anotherObject = ePackage.getEFactoryInstance.create(anotherClass)

    anotherObject.eSet(intAttr, 42)
    anObject.eSet(reference, anotherObject)

    val parser = new Schema.Parser()
    val anotherSchema = parser.parse("""{
      "namespace": "test.avro",
      "type": "record",
      "name": "AnotherClass",
      "fields": [
      {
        "name": "intAttr",
        "type": "int"
      }
      ]
    }""")

    val aSchema = parser.parse("""{
      "namespace": "test.avro",
      "type": "record",
      "name": "AClass",
      "fields": [
      {
        "name": "reference",
        "type": "test.avro.AnotherClass"
      }
      ]
    }""")

    val protocol = new Protocol("Test", null)
    protocol.setTypes(List(anotherSchema, aSchema).asJava)

    When("it is converted")
    val record = EObject2Record.convert(anObject, protocol)

    Then("it should have the reference set correctly")
    record shouldNot be(null)
    val referencedRecord = record.get("reference").asInstanceOf[GenericRecord]
    referencedRecord shouldNot be(null)
    referencedRecord.get("intAttr") shouldEqual 42
  }
}
