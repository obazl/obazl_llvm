#include <clang-c/Index.h>

/* #include <iostream> */
#include <stdio.h>

/* #include <string> */
#include <string.h>

const char *getCursorKindName( enum CXCursorKind cursorKind )
{
    printf("getCursorKindName\n");
  CXString kindName  = clang_getCursorKindSpelling( cursorKind );
  const char *result = clang_getCString( kindName );

  clang_disposeString( kindName );
  return result;
}

const char *getCursorSpelling( CXCursor cursor )
{
    printf("getCursorSpelling\n");
  CXString cursorSpelling = clang_getCursorSpelling( cursor );
  const char *result      = clang_getCString( cursorSpelling );

  clang_disposeString( cursorSpelling );
  return result;
}

enum CXChildVisitResult visitor( CXCursor cursor, CXCursor parent, CXClientData clientData )
{
    printf("visitor\n");
  CXSourceLocation location = clang_getCursorLocation( cursor );
  if( clang_Location_isFromMainFile( location ) == 0 )
    return CXChildVisit_Continue;

  enum CXCursorKind cursorKind = clang_getCursorKind( cursor );

  unsigned int curLevel  = (unsigned int)clientData;

  /* unsigned int curLevel  = *( reinterpret_cast<unsigned int*>( clientData ) ); */

  unsigned int nextLevel = curLevel + 1;

  printf("%d- %s (%s)\n", curLevel,
         getCursorKindName(cursorKind),
         getCursorSpelling(cursor));

  /* std::cout << std::string( curLevel, '-' ) << " " << getCursorKindName( */
  /* cursorKind ) << " (" << getCursorSpelling( cursor ) << ")\n"; */

  clang_visitChildren( cursor,
                       visitor,
                       &nextLevel );

  return CXChildVisit_Continue;
}

int main( int argc, char** argv )
{

  if( argc < 2 )
    return -1;

  CXIndex index        = clang_createIndex( 0, 0 );

  CXTranslationUnit tu;

  enum CXErrorCode ec;

  ec = clang_createTranslationUnit2(index,
                                    argv[1],
                                    &tu);

  printf("EC: %d\n", ec);

/*                                const char *ast_filename, */
/* CXTranslationUnit *out_TU); */


  /* CXTranslationUnit tu = clang_createTranslationUnit( index, */
  /*                                                     /\* "foo.pch"); *\/ */
  /*                                                     argv[1] ); */

  printf("xxxxxxxxxxxxxxxx\n");
  /* char *args[] = { "-Xclang", "-include-pch=foo.pch" }; */
  /* CXTranslationUnit tu = clang_createTranslationUnitFromSourceFile(index, "foo.c", 2, args, 0, 0); */

  if( !tu )
    return -1;

  printf("xxxxxxxxxxxxxxxx\n");

  CXCursor rootCursor  = clang_getTranslationUnitCursor( tu );

  unsigned int treeLevel = 0;

  clang_visitChildren( rootCursor, visitor, &treeLevel );

  clang_disposeTranslationUnit( tu );
  clang_disposeIndex( index );

  return 0;
}
