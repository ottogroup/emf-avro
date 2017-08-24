package com.ottogroup.emfavro

import org.apache.maven.plugin.testing.stubs.MavenProjectStub
import org.apache.maven.model.Resource
import java.util.List

class ResourceProjectStub extends MavenProjectStub {
    private val List<Resource> resources = newArrayList
    override def addResource(Resource resource) {
        resources.add(resource)
    }

    override def getResources() { resources }
}