package com.ottogroup.emfavro

import java.io.FileNotFoundException
import java.nio.file.{Files, Path}

import org.eclipse.emf.codegen.ecore.genmodel.{GenModel, GenModelPackage}
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.xmi.impl.EcoreResourceFactoryImpl

object GenModelLoader {
  def load(path: Path): GenModel = {
    require(path != null, "path must not be null")

    GenModelPackage.eINSTANCE.getGenModel

    val resourceSet = new ResourceSetImpl
    resourceSet.getResourceFactoryRegistry.getExtensionToFactoryMap
        .put(Resource.Factory.Registry.DEFAULT_EXTENSION, new EcoreResourceFactoryImpl)

    val absolutePath = path.toAbsolutePath
    if (!Files.exists(absolutePath))
      throw new FileNotFoundException(absolutePath.toString)

    val uri = URI.createFileURI(absolutePath.toString)
    val resource = resourceSet.getResource(uri, true)
    val content = resource.getContents.get(0)
    if (!content.isInstanceOf[GenModel])
      throw new IllegalArgumentException("The loaded resource contains no GenModel")

    content.asInstanceOf[GenModel]
  }
}
