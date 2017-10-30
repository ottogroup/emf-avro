package com.ottogroup

import org.eclipse.emf.ecore.EClass

package object emfavro {
  implicit class EClassWithImplements(val eClass: EClass) extends AnyRef {
    def implements(interface: EClass): Boolean =
      !eClass.isAbstract && !eClass.isInterface && interface.isSuperTypeOf(eClass)
  }
}
