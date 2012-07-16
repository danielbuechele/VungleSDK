/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "VGSBJsonStreamParserState.h"
#import "VGSBJsonStreamParser.h"

#define SINGLETON \
+ (id)sharedInstance { \
    static id state; \
    if (!state) state = [[self alloc] init]; \
    return state; \
}

@implementation VGJsonStreamParserState

+ (id)sharedInstance { return nil; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	return NO;
}

- (VGSBJsonStreamParserStatus)parserShouldReturn:(VGJsonStreamParser*)parser {
	return VGSBJsonStreamParserWaitingForData;
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {}

- (BOOL)needKey {
	return NO;
}

- (NSString*)name {
	return @"<aaiie!>";
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateStart

SINGLETON

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	return token == VGSBJson_token_array_start || token == VGSBJson_token_object_start;
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {

	VGJsonStreamParserState *state = nil;
	switch (tok) {
		case VGSBJson_token_array_start:
			state = [VGJsonStreamParserStateArrayStart sharedInstance];
			break;

		case VGSBJson_token_object_start:
			state = [VGJsonStreamParserStateObjectStart sharedInstance];
			break;

		case VGSBJson_token_array_end:
		case VGSBJson_token_object_end:
			if (parser.supportMultipleDocuments)
				state = parser.state;
			else
				state = [VGJsonStreamParserStateComplete sharedInstance];
			break;

		case VGSBJson_token_eof:
			return;

		default:
			state = [VGJsonStreamParserStateError sharedInstance];
			break;
	}


	parser.state = state;
}

- (NSString*)name { return @"before outer-most array or object"; }

@end

#pragma mark -

@implementation VGJsonStreamParserStateComplete

SINGLETON

- (NSString*)name { return @"after outer-most array or object"; }

- (VGSBJsonStreamParserStatus)parserShouldReturn:(VGJsonStreamParser*)parser {
	return VGSBJsonStreamParserComplete;
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateError

SINGLETON

- (NSString*)name { return @"in error"; }

- (VGSBJsonStreamParserStatus)parserShouldReturn:(VGJsonStreamParser*)parser {
	return VGSBJsonStreamParserError;
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateObjectStart

SINGLETON

- (NSString*)name { return @"at beginning of object"; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	switch (token) {
		case VGSBJson_token_object_end:
		case VGSBJson_token_string:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey {
	return YES;
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateObjectGotKey

SINGLETON

- (NSString*)name { return @"after object key"; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	return token == VGSBJson_token_keyval_separator;
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateObjectSeparator sharedInstance];
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateObjectSeparator

SINGLETON

- (NSString*)name { return @"as object value"; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	switch (token) {
		case VGSBJson_token_object_start:
		case VGSBJson_token_array_start:
		case VGSBJson_token_true:
		case VGSBJson_token_false:
		case VGSBJson_token_null:
		case VGSBJson_token_number:
		case VGSBJson_token_string:
			return YES;
			break;

		default:
			return NO;
			break;
	}
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateObjectGotValue sharedInstance];
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateObjectGotValue

SINGLETON

- (NSString*)name { return @"after object value"; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	switch (token) {
		case VGSBJson_token_object_end:
		case VGSBJson_token_separator:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateObjectNeedKey sharedInstance];
}


@end

#pragma mark -

@implementation VGJsonStreamParserStateObjectNeedKey

SINGLETON

- (NSString*)name { return @"in place of object key"; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
    return VGSBJson_token_string == token;
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey {
	return YES;
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateArrayStart

SINGLETON

- (NSString*)name { return @"at array start"; }

- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	switch (token) {
		case VGSBJson_token_object_end:
		case VGSBJson_token_keyval_separator:
		case VGSBJson_token_separator:
			return NO;
			break;

		default:
			return YES;
			break;
	}
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateArrayGotValue sharedInstance];
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateArrayGotValue

SINGLETON

- (NSString*)name { return @"after array value"; }


- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	return token == VGSBJson_token_array_end || token == VGSBJson_token_separator;
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	if (tok == VGSBJson_token_separator)
		parser.state = [VGJsonStreamParserStateArrayNeedValue sharedInstance];
}

@end

#pragma mark -

@implementation VGJsonStreamParserStateArrayNeedValue

SINGLETON

- (NSString*)name { return @"as array value"; }


- (BOOL)parser:(VGJsonStreamParser*)parser shouldAcceptToken:(VGSBJson_token_t)token {
	switch (token) {
		case VGSBJson_token_array_end:
		case VGSBJson_token_keyval_separator:
		case VGSBJson_token_object_end:
		case VGSBJson_token_separator:
			return NO;
			break;

		default:
			return YES;
			break;
	}
}

- (void)parser:(VGJsonStreamParser*)parser shouldTransitionTo:(VGSBJson_token_t)tok {
	parser.state = [VGJsonStreamParserStateArrayGotValue sharedInstance];
}

@end

