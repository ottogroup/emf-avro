package com.ottogroup.emfavro

import org.junit.rules.TestRule
import org.junit.runner.Description
import org.junit.runners.model.Statement

trait JUnitRules {
  def withRule[T <: TestRule](rule: T)(test: T => Any): Unit = rule(
    new Statement {
      override def evaluate(): Unit = test(rule)
    },
    Description.createSuiteDescription("JUnit rule wrapper")
  ).evaluate()
}
