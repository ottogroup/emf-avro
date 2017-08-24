package com.ottogroup.emfavro

import java.io.ByteArrayInputStream
import org.apache.avro.compiler.idl.Idl

class Main {
    def static void main(String[] args) {
        val loader = new GenModelLoader
        val genModel = loader.load(args.head)

        val idlStr = new IDLGenerator().generateIdl(genModel).toString
        val input = new ByteArrayInputStream(idlStr.getBytes("UTF-8"))
        val protocol = new Idl(input).CompilationUnit
        println(protocol.toString(true))
    }
}