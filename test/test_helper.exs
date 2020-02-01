# Since we use in-memory module stubs in some tests this warning is getting
# disabled to avoid unecessary noise in the tests output.
Code.compiler_options(ignore_module_conflict: true)
ExUnit.start()
