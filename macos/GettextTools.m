//
//  GettextTools.c
//  GettextTools
//
//  This file is in public domain.
//


// Xcode has issues with signing plugins/bundles that don't actually have
// a binary in them. To work around this limitation, create a tiny dummy
// plugin binary with a dummy function in it.
int lets_keep_xcode_codesigning_happy_la_la_la(void)
{
    return 42;
}
