package com.ottogroup.emfavro

import java.nio.file.Paths
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenModelPackage
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl

class GenModelLoader {
    private val resourceSet = new ResourceSetImpl()

    new () {
        GenModelPackage.eINSTANCE.eClass
        val extensionMap = resourceSet.resourceFactoryRegistry.extensionToFactoryMap
        extensionMap.put("ecore", new EcoreResourceFactoryImpl)
        extensionMap.put("genmodel", new EcoreResourceFactoryImpl)
    }

    def GenModel load(String path) {
        val absolutePath = Paths.get(path).toAbsolutePath
        val uri = URI.createFileURI(absolutePath.toString)
        val resource = resourceSet.getResource(uri, true)

        if (resource.contents.isEmpty) {
            throw new IllegalArgumentException("the genmodel file has no package");
        }

        resource.contents.head as GenModel
    }
}