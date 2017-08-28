package com.ottogroup.emfavro

import java.io.FileNotFoundException
import java.nio.file.Files
import java.nio.file.Path
import java.util.Objects
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenModelPackage
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl

class GenModelLoader {
    static def GenModel load(Path path) {
        Objects.requireNonNull(path, ["path is null"])

        // triggers GenModelPackageImpl.init()
        GenModelPackage.eINSTANCE.genModel

        val resourceSet = new ResourceSetImpl
        resourceSet.resourceFactoryRegistry.extensionToFactoryMap
            .put(Resource.Factory.Registry.DEFAULT_EXTENSION, new EcoreResourceFactoryImpl)

        val absolutePath = path.toAbsolutePath
        if (!Files.exists(absolutePath))
            throw new FileNotFoundException(absolutePath.toString)

        val uri = URI.createFileURI(absolutePath.toString)
        val resource = resourceSet.getResource(uri, true)
        val content = resource.contents.head
        if (!(content instanceof GenModel))
            throw new IllegalArgumentException("The loaded resource contains no GenModel")

        content as GenModel
    }
}