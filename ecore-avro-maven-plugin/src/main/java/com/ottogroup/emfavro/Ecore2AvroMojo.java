package com.ottogroup.emfavro;

import org.apache.avro.Protocol;
import org.apache.maven.model.Resource;
import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.apache.maven.plugin.MojoFailureException;
import org.apache.maven.plugins.annotations.LifecyclePhase;
import org.apache.maven.plugins.annotations.Mojo;
import org.apache.maven.plugins.annotations.Parameter;
import org.apache.maven.project.MavenProject;
import org.eclipse.emf.codegen.ecore.genmodel.GenModel;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Mojo(name = "generate", defaultPhase = LifecyclePhase.GENERATE_RESOURCES)
public class Ecore2AvroMojo extends AbstractMojo {
    @Parameter(defaultValue = "${project}", required = true, readonly = true)
    private MavenProject project;

    @Parameter(required = true)
    private File genModel;

    @Parameter(defaultValue = "${project.build.directory}/generated-resources/avro")
    private File outputDirectory;

    @Override
    public void execute() throws MojoExecutionException, MojoFailureException {
        GenModel model = GenModelLoader.load(genModel.toPath());
        getLog().info("Processing " + model.getGenPackages().size() + " GenPackages");

        Protocol protocol = Ecore2Avro.convert(model);

        Path outputPath = outputDirectory.toPath();
        for (String pkg : protocol.getNamespace().split("\\.")) {
            outputPath = outputPath.resolve(pkg);
        }
        outputPath = outputPath.resolve(protocol.getName() + ".avpr");

        try {
            Files.createDirectories(outputPath.getParent());
            Files.write(outputPath, protocol.toString().getBytes());
        } catch (IOException e) {
            throw new MojoExecutionException("Error writing the Avro protocol file", e);
        }

        Resource resource = new Resource();
        resource.setDirectory(outputDirectory.getPath());
        project.addResource(resource);
    }
}
