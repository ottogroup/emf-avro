package com.ottogroup.emfavro

import java.io.File
import java.io.FileNotFoundException
import java.nio.file.Files
import org.apache.maven.model.Resource
import org.apache.maven.plugin.AbstractMojo
import org.apache.maven.plugin.MojoExecutionException
import org.apache.maven.plugins.annotations.LifecyclePhase
import org.apache.maven.plugins.annotations.Mojo
import org.apache.maven.plugins.annotations.Parameter
import org.apache.maven.project.MavenProject

@Mojo(name = "generate", defaultPhase = LifecyclePhase.GENERATE_SOURCES)
class Ecore2AvroMojo extends AbstractMojo {
    @Parameter(defaultValue = "${project}", required = true, readonly = true)
    private var MavenProject project;

    @Parameter(required = true)
    private var File genModel;

    @Parameter(defaultValue = "${project.build.directory}/generated-resources/avro")
    private var File outputDirectory;

    def override void execute() throws MojoExecutionException {
        if (!outputDirectory.exists) outputDirectory.mkdirs
        if (!genModel.exists) throw new FileNotFoundException(genModel.toString)

        val loader = new GenModelLoader
        val genModel = loader.load(genModel.toPath)
        log.info('''Processing «genModel.genPackages.size» GenPackages''')

        val protocol = Ecore2Avro.convert(genModel)
        val outputPath = outputDirectory.toPath.resolve(protocol.name + ".avpr");
        Files.write(outputPath, protocol.toString(true).getBytes)

        val resource = new Resource
        resource.setDirectory(outputDirectory.path)
        project.addResource(resource);
    }
}