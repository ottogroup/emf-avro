package com.ottogroup.emfavro

import java.io.FileNotFoundException
import java.nio.file.Paths

import org.eclipse.emf.common.util.WrappedException
import org.scalatest.{FlatSpec, GivenWhenThen, Matchers}

class GenModelLoaderSpec extends FlatSpec with GivenWhenThen with Matchers {
  "A GenModelLoader" should "throw an IllegalArgumentException for a null parameter" in {
    a [IllegalArgumentException] should be thrownBy GenModelLoader.load(null)
  }

  it should "throw a FileNotFoundException if the path is not existent" in {
    Given("a nonexisting path")
    val path = Paths.get("nonexisting_path")
    When("the path is loaded")
    Then("a FileNotFoundException should be thrown")
    a [FileNotFoundException] should be thrownBy GenModelLoader.load(path)
  }

  it should "throw a WrappedException if the genmodel is not valid" in {
    Given("a path leading to an invalid genmodel")
    val path = Paths.get(getClass.getResource("/invalid.genmodel").toURI)

    When("the path is loaded")
    Then("a WrappedException should be thrown")
    a [WrappedException] should be thrownBy GenModelLoader.load(path)
  }

  it should "load an empty genmodel" in {
    Given("A path leading to an empty genmodel")
    val path = Paths.get(getClass.getResource("/empty.genmodel").toURI)

    When("The path is loaded")
    val genModel = GenModelLoader.load(path)

    Then("It should be loaded correctly")
    genModel shouldNot be(null)
    genModel.getModelName shouldEqual "Test"
    genModel.getGenPackages should have size 0
  }

  it should "throw a RuntimeException if the loaded resource contains no genmodel" in {
    Given("a Path leading to an ECore resource")
    val path = Paths.get(getClass.getResource("/empty.ecore").toURI)

    When("the model is loaded")
    Then("a RuntimeException should be thrown")
    a [RuntimeException] should be thrownBy GenModelLoader.load(path)
  }
}
