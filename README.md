# EMF → Avro M2M
[![Build Status](https://travis-ci.org/ottogroup/emf-avro.svg?branch=master)](https://travis-ci.org/ottogroup/emf-avro) [![Coverage Status](https://coveralls.io/repos/github/ottogroup/emf-avro/badge.svg?branch=master)](https://coveralls.io/github/ottogroup/emf-avro?branch=master)

*emf-avro* is a M2M transformation to convert EMF schemas and instances to Avro schemas and records. 
It consists of three modules:

* *ecore-avro*: converts a GenModel-backed Ecore model to an Avro protocol, which defines multiple schemas
* *ecore-avro-maven-plugin*: a Maven 3 plugin, which can be used to integrate the former step in your build process
* *eobject-record*: converts EMF `EObject`s to Avro `Record` instances, which will conform to the generated schema
