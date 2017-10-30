package com.ottogroup.emfavro

import java.nio.file.Paths
import java.util.Date

import org.apache.avro.Schema.Type
import org.apache.avro.{Protocol, Schema}
import org.eclipse.emf.codegen.ecore.genmodel.GenModelFactory
import org.eclipse.emf.ecore.{EcoreFactory, EcorePackage}
import org.junit.contrib.java.lang.system.{ExpectedSystemExit, SystemOutRule}
import org.scalatest.{FlatSpec, GivenWhenThen, Matchers}

import scala.collection.JavaConverters._

class Ecore2AvroSpec extends FlatSpec with Matchers with GivenWhenThen with JUnitRules {
  "The Ecore2Avro converter" should "throw an IllegalArgumentException for a null parameter" in {
    an[IllegalArgumentException] should be thrownBy Ecore2Avro.convert(null)
  }

  it should "throw a IllegalArgumentException if there is no genpackage" in {
    Given("a genmodel with no genpackages")
    val genModel = GenModelFactory.eINSTANCE.createGenModel()
    genModel.setModelName("Test Model")

    When("it is converted")
    Then("an IllegalArgumentException should be thrown")
    an[IllegalArgumentException] should be thrownBy Ecore2Avro.convert(genModel)
  }

  it should "not mark neither abstract classes nor data types to be converted" in {
    Given("a data type, enum, abstract and concrete class")
    val abstractClass = EcoreFactory.eINSTANCE.createEClass()
    abstractClass.setAbstract(true)
    val dataType = EcoreFactory.eINSTANCE.createEDataType()
    val enum = EcoreFactory.eINSTANCE.createEEnum()
    val concreteClass = EcoreFactory.eINSTANCE.createEClass()

    When("they are tested against the shouldBeConverted predicate")
    Then("it should return true only for the concrete class")
    Ecore2Avro.shouldBeConverted(abstractClass) should be(false)
    Ecore2Avro.shouldBeConverted(dataType) should be(false)
    Ecore2Avro.shouldBeConverted(enum) should be(true)
    Ecore2Avro.shouldBeConverted(concreteClass) should be(true)
  }

  it should "convert an enum correctly" in {
    Given("an enum with three literals")
    val literal1 = EcoreFactory.eINSTANCE.createEEnumLiteral()
    literal1.setName("Literal1")
    val literal2 = EcoreFactory.eINSTANCE.createEEnumLiteral()
    literal2.setName("Literal2")
    val literal3 = EcoreFactory.eINSTANCE.createEEnumLiteral()
    literal3.setName("Literal3")

    val enum = EcoreFactory.eINSTANCE.createEEnum()
    enum.setName("TestEnum")
    enum.getELiterals.addAll(Seq(literal1, literal2, literal3).asJava)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("leaf")
    ePackage.getEClassifiers.add(enum)

    val ecorePackage = EcorePackage.eINSTANCE
    ecorePackage.getEClassifiers.add(enum)

    val genPackage = GenModelFactory.eINSTANCE.createGenPackage()
    genPackage.setBasePackage("com.base.package")
    genPackage.setEcorePackage(ecorePackage)

    When("it is converted to a schema")
    val schema = Ecore2Avro.toAvroSchema(enum, genPackage.getBasePackage)

    Then("it should be of schema type ENUM and have the three literals")
    schema shouldNot be(null)
    schema.getType shouldEqual Schema.Type.ENUM
    schema.getEnumSymbols should contain only("Literal1", "Literal2", "Literal3")
  }

  it should "convert primitve attributes correctly" in {
    Given("attributes for each primitive type")
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

    When("they are converted to fields")
    val booleanField = Ecore2Avro.toAvroField(booleanAttr, null, null)
    val intField = Ecore2Avro.toAvroField(intAttr, null, null)
    val longField = Ecore2Avro.toAvroField(longAttr, null, null)
    val floatField = Ecore2Avro.toAvroField(floatAttr, null, null)
    val doubleField = Ecore2Avro.toAvroField(doubleAttr, null, null)
    val stringField = Ecore2Avro.toAvroField(stringAttr, null, null)
    val wrappingField = Ecore2Avro.toAvroField(wrappingAttr, null, null)

    Then("name and schema type should be correct for each")
    booleanField.name shouldEqual "booleanAttr"
    intField.name shouldEqual "intAttr"
    longField.name shouldEqual "longAttr"
    floatField.name shouldEqual "floatAttr"
    doubleField.name shouldEqual "doubleAttr"
    stringField.name shouldEqual "stringAttr"
    wrappingField.name shouldEqual "wrappingAttr"

    booleanField.schema.getType shouldEqual Schema.Type.BOOLEAN
    intField.schema.getType shouldEqual Schema.Type.INT
    longField.schema.getType shouldEqual Schema.Type.LONG
    floatField.schema.getType shouldEqual Schema.Type.FLOAT
    doubleField.schema.getType shouldEqual Schema.Type.DOUBLE
    stringField.schema.getType shouldEqual Schema.Type.STRING
    wrappingField.schema.getType shouldEqual Schema.Type.STRING
  }

  it should "convert a reference to a class correctly" in {
    Given("a reference to a simple class")
    val eClass = EcoreFactory.eINSTANCE.createEClass()
    eClass.setName("TestClass")

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("leaf")
    ePackage.getEClassifiers.add(eClass)

    val ecorePackage = EcorePackage.eINSTANCE
    ecorePackage.getEClassifiers.add(eClass)

    val genPackage = GenModelFactory.eINSTANCE.createGenPackage()
    genPackage.setBasePackage("com.base.package")
    genPackage.setEcorePackage(ecorePackage)

    val genModel = GenModelFactory.eINSTANCE.createGenModel()
    genModel.setModelName("TestModel")
    genModel.getGenPackages.add(genPackage)

    val ref = EcoreFactory.eINSTANCE.createEReference()
    ref.setName("ref")
    ref.setEType(eClass)

    When("it is converted to a field")
    val field = Ecore2Avro.toAvroField(ref, genPackage.getBasePackage, genModel)

    Then("the field name and schema should be correct")
    val testClassSchema = Ecore2Avro.toAvroSchema(eClass, genPackage.getBasePackage, genModel)
    field shouldNot be(null)
    field.name shouldEqual "ref"
    field.schema shouldEqual testClassSchema
  }

  it should "convert a reference to an interface correctly" in {
    Given("a reference to an interface with 2 implementations")
    val intrface = EcoreFactory.eINSTANCE.createEClass()
    intrface.setName("MyInterface")
    intrface.setInterface(true)

    val impl1 = EcoreFactory.eINSTANCE.createEClass()
    impl1.setName("MyInterfaceImpl1")
    impl1.getESuperTypes.add(intrface)

    val impl2 = EcoreFactory.eINSTANCE.createEClass()
    impl2.setName("MyInterfaceImpl2")
    impl2.getESuperTypes.add(intrface)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("leaf")
    ePackage.getEClassifiers.addAll(List(intrface, impl1, impl2).asJava)

    val ecorePackage = EcorePackage.eINSTANCE
    ecorePackage.getEClassifiers.addAll(List(intrface, impl1, impl2).asJava)

    val genPackage = GenModelFactory.eINSTANCE.createGenPackage()
    genPackage.setBasePackage("com.base.package")
    genPackage.setEcorePackage(ecorePackage)

    val genModel = GenModelFactory.eINSTANCE.createGenModel()
    genModel.setModelName("TestModel")
    genModel.getGenPackages.add(genPackage)

    val ref = EcoreFactory.eINSTANCE.createEReference()
    ref.setName("ref")
    ref.setEType(intrface)

    When("it is converted to a field")
    val field = Ecore2Avro.toAvroField(ref, genPackage.getBasePackage, genModel)

    Then("the field name and schema should be correct")
    val impl1Schema = Ecore2Avro.toAvroSchema(impl1, genPackage.getBasePackage, genModel)
    val impl2Schema = Ecore2Avro.toAvroSchema(impl2, genPackage.getBasePackage, genModel)

    field shouldNot be(null)
    field.name shouldEqual "ref"
    field.schema.getType should be(Type.UNION)
    field.schema.getTypes should contain only(impl1Schema, impl2Schema)
  }

  it should "find implementations for an interface" in {
    Given("a reference to an interface with 1 implementation")
    val intrface = EcoreFactory.eINSTANCE.createEClass()
    intrface.setName("MyInterface")
    intrface.setInterface(true)

    val impl1 = EcoreFactory.eINSTANCE.createEClass()
    impl1.setName("MyInterfaceImpl1")
    impl1.getESuperTypes.add(intrface)

    val impl2 = EcoreFactory.eINSTANCE.createEClass()
    impl2.setName("MyInterfaceImpl2")

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("leaf")
    ePackage.getEClassifiers.addAll(List(intrface, impl1, impl2).asJava)

    val ecorePackage = EcorePackage.eINSTANCE
    ecorePackage.getEClassifiers.addAll(List(intrface, impl1, impl2).asJava)

    val genPackage = GenModelFactory.eINSTANCE.createGenPackage()
    genPackage.setBasePackage("com.base.package")
    genPackage.setEcorePackage(ecorePackage)

    val genModel = GenModelFactory.eINSTANCE.createGenModel()
    genModel.setModelName("TestModel")
    genModel.getGenPackages.add(genPackage)

    When("it searches for implementaions of that interface")
    val impls = Ecore2Avro.findImplementations(intrface, genModel)

    Then("it should find the given one")
    impls should not be empty
    impls should contain only impl1
  }

  it should "convert a class containing several attributes correctly" in {
    Given("a class containing attributes for each primitive type")
    val booleanAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val intAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val longAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val floatAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val doubleAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val stringAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val enumAttr = EcoreFactory.eINSTANCE.createEAttribute()
    val wrappingAttr = EcoreFactory.eINSTANCE.createEAttribute()

    val dateDataType = EcoreFactory.eINSTANCE.createEDataType()
    dateDataType.setInstanceClass(classOf[Date])

    val enum = EcoreFactory.eINSTANCE.createEEnum()
    enum.setName("TestEnum")

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
    enumAttr.setName("enumAttr")
    enumAttr.setEType(enum)
    wrappingAttr.setName("wrappingAttr")
    wrappingAttr.setEType(dateDataType)

    val eClass = EcoreFactory.eINSTANCE.createEClass()
    eClass.setName("TestClass")
    eClass.getEStructuralFeatures.addAll(List(booleanAttr, intAttr, longAttr, floatAttr,
      doubleAttr, stringAttr, enumAttr, wrappingAttr).asJava)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("leaf")
    ePackage.getEClassifiers.addAll(List(eClass, enum).asJava)

    val genPackage = GenModelFactory.eINSTANCE.createGenPackage()
    genPackage.setBasePackage("com.base.package")

    val genModel = GenModelFactory.eINSTANCE.createGenModel()
    genModel.setModelName("TestModel")
    genModel.getGenPackages.add(genPackage)

    When("it is converted to a schema")
    val schema = Ecore2Avro.toAvroSchema(eClass, genPackage.getBasePackage, genModel)

    Then("it should be converted correctly")
    schema shouldNot be(null)
    schema.getNamespace shouldEqual "com.base.package.leaf.avro"
    schema.getType should be(Type.RECORD)
    schema.getName shouldEqual "TestClass"
    schema.getFields should have size 8
    schema.getField("booleanAttr").schema.getType should be(Type.BOOLEAN)
    schema.getField("intAttr").schema.getType should be(Type.INT)
    schema.getField("longAttr").schema.getType should be(Type.LONG)
    schema.getField("floatAttr").schema.getType should be(Type.FLOAT)
    schema.getField("doubleAttr").schema.getType should be(Type.DOUBLE)
    schema.getField("stringAttr").schema.getType should be(Type.STRING)
    schema.getField("enumAttr").schema.getType should be(Type.ENUM)
    schema.getField("wrappingAttr").schema.getType should be(Type.STRING)
  }

  it should "recognize an implementation of an interface" in {
    Given("an interface with an implementation")
    val intrface = EcoreFactory.eINSTANCE.createEClass()
    intrface.setName("MyInterface")
    intrface.setInterface(true)

    val impl = EcoreFactory.eINSTANCE.createEClass()
    impl.setName("MyInterfaceImpl")
    impl.getESuperTypes.add(intrface)

    When("it is asked if the implementation implements the interface")
    val isImplementation = impl implements intrface

    Then("it should return true")
    isImplementation should be(true)
  }

  it should "not recognize a class not implementing an interface of an implementation" in {
    Given("an interface and another class")
    val intrface = EcoreFactory.eINSTANCE.createEClass()
    intrface.setName("MyInterface")
    intrface.setInterface(true)

    val noImpl = EcoreFactory.eINSTANCE.createEClass()
    noImpl.setName("NoImplementation")

    When("it is asked if the class implements the interface")
    val isImplementation = noImpl implements intrface

    Then("it should return false")
    isImplementation should be(false)
  }

  it should "convert a class containing a reference correctly" in {
    Given("a class containing a reference to another class")

    val intAttr = EcoreFactory.eINSTANCE.createEAttribute()
    intAttr.setName("intAttr")
    intAttr.setEType(EcorePackage.Literals.EINT)

    val anotherClass = EcoreFactory.eINSTANCE.createEClass()
    anotherClass.setName("AnotherClass")
    anotherClass.getEStructuralFeatures.add(intAttr)

    val reference = EcoreFactory.eINSTANCE.createEReference()
    reference.setName("ref")
    reference.setEType(anotherClass)

    val aClass = EcoreFactory.eINSTANCE.createEClass()
    aClass.setName("AClass")
    aClass.getEStructuralFeatures.add(reference)

    val ePackage = EcoreFactory.eINSTANCE.createEPackage()
    ePackage.setName("leaf")
    ePackage.getEClassifiers.addAll(List(anotherClass, aClass).asJava)

    When("it is converted")
    val schema = Ecore2Avro.toAvroSchema(aClass, "com.base.package", null)

    Then("it should be converted correctly")
    schema shouldNot be(null)
    schema.getNamespace shouldEqual "com.base.package.leaf.avro"
    schema.getName shouldEqual "AClass"
    schema.getType should be(Type.RECORD)
    schema.getFields should have size 1
    val referencedSchema = schema.getField("ref").schema
    referencedSchema.getType should be(Type.RECORD)
    referencedSchema.getFields should have size 1
    referencedSchema.getField("intAttr").schema.getType should be(Type.INT)
  }

  it should "convert list types correctly" in {
    Given("an unbounded list of strings attribute")
    val listOfStringsAttr = EcoreFactory.eINSTANCE.createEAttribute()
    listOfStringsAttr.setName("listOfStrings")
    listOfStringsAttr.setEType(EcorePackage.Literals.ESTRING)
    listOfStringsAttr.setUpperBound(-1)

    When("it is converted")
    val field = Ecore2Avro.toAvroField(listOfStringsAttr, "com.base.package", null)

    Then("it should be converted correctly")
    field shouldNot be(null)
    field.name shouldEqual "listOfStrings"
    field.schema.getType should be(Type.ARRAY)
    field.schema.getElementType.getType should be(Type.STRING)
  }

  it should "convert a complete genmodel correctly" in {
    Given("a sample genmodel with some stuff")
    val genModelPath = Paths.get(getClass.getResource("/test.genmodel").toURI)
    val genModel = GenModelLoader.load(genModelPath)

    When("it is converted")
    val protocol = Ecore2Avro.convert(genModel)

    Then("it should be converted correctly")
    protocol should not be null
    protocol.getName shouldEqual "Test"
    protocol.getNamespace shouldEqual "base"
    protocol.getMessages shouldBe empty
    protocol.getTypes should have size 5
    protocol.getType("base.test.avro.WeekDay").getType should be(Type.ENUM)
    protocol.getType("base.test.avro.Primitives").getType should be(Type.RECORD)
    protocol.getType("base.test.avro.Referencer").getType should be(Type.RECORD)
    protocol.getType("base.test.avro.InterfaceImpl1").getType should be(Type.RECORD)
    protocol.getType("base.test.avro.InterfaceImpl2").getType should be(Type.RECORD)
  }

  it should "convert a given genmodel file to the main method correctly" in withRule(new SystemOutRule) { systemOutRule =>
    Given("a sample genmodel with some stuff")
    val genModelPath = Paths.get(getClass.getResource("/test.genmodel").toURI)

    When("the main method is called with 1 parameter")
    systemOutRule.enableLog()
    Ecore2Avro.main(Array(genModelPath.toString))

    Then("it should be converted correctly")
    val protocolStr = new String(systemOutRule.getLog)
    val protocol = Protocol.parse(protocolStr)
    protocol should not be null
    protocol.getName shouldEqual "Test"
    protocol.getNamespace shouldEqual "base"
    protocol.getMessages shouldBe empty
    protocol.getTypes should have size 5
    protocol.getType("base.test.avro.WeekDay").getType should be(Type.ENUM)
    protocol.getType("base.test.avro.Primitives").getType should be(Type.RECORD)
    protocol.getType("base.test.avro.Referencer").getType should be(Type.RECORD)
    protocol.getType("base.test.avro.InterfaceImpl1").getType should be(Type.RECORD)
    protocol.getType("base.test.avro.InterfaceImpl2").getType should be(Type.RECORD)
  }

  it should "exit with code 1 when no arg is given to main()" in withRule(ExpectedSystemExit.none()) { exit =>
    exit.expectSystemExitWithStatus(1)
    Ecore2Avro.main(Array())
  }
}