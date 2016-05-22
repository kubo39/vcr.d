import vcr;

import std.stdio;
import core.stdc.stdlib : malloc, free;

void main()
{
    assert(runningOnValgrind() == 1);

    char* x = cast(char*) malloc(char.sizeof * 4);
    free(x);
    free(x);

    assert(countErrors() > 0);
}
