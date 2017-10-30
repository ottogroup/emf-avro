package com.ottogroup.emfavro

import java.util

import org.apache.maven.model.Resource
import org.apache.maven.plugin.testing.stubs.MavenProjectStub

import scala.collection.JavaConverters._
import scala.collection.mutable

class ResourceProjectStub extends MavenProjectStub {
  private val resources = mutable.Set[Resource]()

  override def addResource(resource: Resource): Unit = resources += resource

  override def getResources: util.List[Resource] = resources.toList.asJava
}
