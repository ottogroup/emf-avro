package com.ottogroup.emfavro

import com.google.common.base.Preconditions
import java.io.FileNotFoundException
import java.nio.file.Files
import java.nio.file.Path
import org.eclipse.emf.codegen.ecore.genmodel.GenModel
import org.eclipse.emf.codegen.ecore.genmodel.GenModelPackage
import org.eclipse.emf.common.util.Diagnostic
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.util.Diagnostician
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl

class GenModelLoader {
    private val resourceSet = new ResourceSetImpl()

    new () {
        GenModelPackage.eINSTANCE.eClass
        val extensionMap = resourceSet.resourceFactoryRegistry.extensionToFactoryMap
        extensionMap.put("ecore", new EcoreResourceFactoryImpl)
        extensionMap.put("genmodel", new EcoreResourceFactoryImpl)
    }

    def GenModel load(Path path) {
        Preconditions.checkNotNull(path)

        val absolutePath = path.toAbsolutePath
        if (!Files.exists(absolutePath))
            throw new FileNotFoundException(absolutePath.toString)

        val uri = URI.createFileURI(absolutePath.toString)
        val resource = resourceSet.getResource(uri, true)

        val content = resource.contents.head
        if (!(content instanceof GenModel))
            throw new IllegalArgumentException("The loaded resource contains no GenModel")

        val diagnostic = Diagnostician.INSTANCE.validate(content)
        if (diagnostic.severity != Diagnostic.OK) {
            throw new IllegalStateException("The loaded GenModel is not valid: " + diagnostic.message)
        }

        resource.contents.head as GenModel
    }
}