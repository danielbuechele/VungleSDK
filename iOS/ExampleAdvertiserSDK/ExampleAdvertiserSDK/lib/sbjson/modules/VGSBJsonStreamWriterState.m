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

#import "VGSBJsonStreamWriterState.h"
#import "VGSBJsonStreamWriter.h"

#define SINGLETON \
+ (id)sharedInstance { \
    static id state; \
    if (!state) state = [[self alloc] init]; \
    return state; \
}


@implementation VGJsonStreamWriterState
+ (id)sharedInstance { return nil; }
- (BOOL)isInvalidState:(VGJsonStreamWriter*)writer { return NO; }
- (void)appendSeparator:(VGJsonStreamWriter*)writer {}
- (BOOL)expectingKey:(VGJsonStreamWriter*)writer { return NO; }
- (void)transitionState:(VGJsonStreamWriter *)writer {}
- (void)appendWhitespace:(VGJsonStreamWriter*)writer {
	[writer appendBytes:"\n" length:1];
	for (NSUInteger i = 0; i < writer.stateStack.count; i++)
	    [writer appendBytes:"  " length:2];
}
@end

@implementation VGJsonStreamWriterStateObjectStart

SINGLETON

- (void)transitionState:(VGJsonStreamWriter *)writer {
	writer.state = [VGJsonStreamWriterStateObjectValue sharedInstance];
}
- (BOOL)expectingKey:(VGJsonStreamWriter *)writer {
	writer.error = @"JSON object key must be string";
	return YES;
}
@end

@implementation VGJsonStreamWriterStateObjectKey

SINGLETON

- (void)appendSeparator:(VGJsonStreamWriter *)writer {
	[writer appendBytes:"," length:1];
}
@end

@implementation VGJsonStreamWriterStateObjectValue

SINGLETON

- (void)appendSeparator:(VGJsonStreamWriter *)writer {
	[writer appendBytes:":" length:1];
}
- (void)transitionState:(VGJsonStreamWriter *)writer {
    writer.state = [VGJsonStreamWriterStateObjectKey sharedInstance];
}
- (void)appendWhitespace:(VGJsonStreamWriter *)writer {
	[writer appendBytes:" " length:1];
}
@end

@implementation VGJsonStreamWriterStateArrayStart

SINGLETON

- (void)transitionState:(VGJsonStreamWriter *)writer {
    writer.state = [VGJsonStreamWriterStateArrayValue sharedInstance];
}
@end

@implementation VGJsonStreamWriterStateArrayValue

SINGLETON

- (void)appendSeparator:(VGJsonStreamWriter *)writer {
	[writer appendBytes:"," length:1];
}
@end

@implementation VGJsonStreamWriterStateStart

SINGLETON


- (void)transitionState:(VGJsonStreamWriter *)writer {
    writer.state = [VGJsonStreamWriterStateComplete sharedInstance];
}
- (void)appendSeparator:(VGJsonStreamWriter *)writer {
}
@end

@implementation VGJsonStreamWriterStateComplete

SINGLETON

- (BOOL)isInvalidState:(VGJsonStreamWriter*)writer {
	writer.error = @"Stream is closed";
	return YES;
}
@end

@implementation VGJsonStreamWriterStateError

SINGLETON

@end

