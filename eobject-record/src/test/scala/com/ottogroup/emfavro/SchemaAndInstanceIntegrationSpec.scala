package com.ottogroup.emfavro

import java.nio.file.Paths

import org.apache.avro.generic.GenericData.EnumSymbol
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EPackage
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.XMIResourceFactoryImpl
import org.scalatest.{FlatSpec, GivenWhenThen, Matchers}

class SchemaAndInstanceIntegrationSpec extends FlatSpec with Matchers with GivenWhenThen {
  "A XMI resource" should "be converted to Avro correctly" in {
    Given("An XMI resource with a corresponding GenModel+Ecore model")

    val genModelPath = Paths.get(getClass.getResource("/test.genmodel").toURI)
    val genModel = GenModelLoader.load(genModelPath)
    val testPackage = genModel.getGenPackages.get(0).getEcorePackage
    EPackage.Registry.INSTANCE.put(testPackage.getNsURI, testPackage)

    val resourceSet = new ResourceSetImpl
    resourceSet.getResourceFactoryRegistry.getExtensionToFactoryMap.put("test", new XMIResourceFactoryImpl)

    val uri = URI.createURI(getClass.getResource("/primitives.test").toString)
    val resource = resourceSet.getResource(uri, true)
    val primitives = resource.getContents.get(0)

    When("The schema and resource are converted")
    val protocol = Ecore2Avro.convert(genModel)
    val record = EObject2Record.convert(primitives, protocol)

    Then("All values should be set correctly")
    record shouldNot be(null)
    record.get("booleanAttr") shouldEqual true
    record.get("intAttr") shouldEqual 42
    record.get("longAttr") shouldEqual 1337L
    record.get("floatAttr") shouldEqual 3.14f
    record.get("doubleAttr") shouldEqual 123.456789
    record.get("stringAttr") shouldEqual "foo"
    record.get("weekDay") shouldBe an [EnumSymbol]
    record.get("weekDay").toString shouldEqual "FRIDAY"
  }

}
