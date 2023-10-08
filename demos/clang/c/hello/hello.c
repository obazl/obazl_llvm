#include <clang-c/Index.h>
#include <stdio.h>

int main(){
  CXIndex index = clang_createIndex(0, 0); //Create index
  CXTranslationUnit unit = clang_parseTranslationUnit(
    index,
    "file.cpp", nullptr, 0,
    nullptr, 0,
    CXTranslationUnit_None); //Parse "file.cpp"


  if (unit == NULL){
      printf("Unable to parse translation unit. Quitting.\n");
      return 0;
  }

  CXCursor cursor = clang_getTranslationUnitCursor(unit); //Obtain a cursor at the root of the translation unit
}
