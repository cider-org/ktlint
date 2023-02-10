package com.pinterest.ktlint.core.api.editorconfig

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource

class CodeStyleEditorConfigPropertyTest {
    @ParameterizedTest(name = "Value: [{0}], result: [{1}]")
    @CsvSource(
        value = [
            "official,official",
            " official,official",
            "official ,official",
            " official ,official",
            "android,android",
            " android,android",
            "android ,android",
            " android ,android",
        ],
        ignoreLeadingAndTrailingWhitespace = false,
    )
    fun `Given a code style property`(
        value: String,
        expectedCodeStyleValue: CodeStyleValue,
    ) {
        val actual = CODE_STYLE_PROPERTY.type.parse(value)

        assertThat(actual.parsed).isEqualTo(expectedCodeStyleValue)
    }
}
