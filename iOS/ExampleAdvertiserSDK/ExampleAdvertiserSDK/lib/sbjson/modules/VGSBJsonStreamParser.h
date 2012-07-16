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

#import <Foundation/Foundation.h>

@class VGJsonTokeniser;
@class VGJsonStreamParser;
@class VGJsonStreamParserState;

typedef enum {
	VGSBJsonStreamParserComplete,
	VGSBJsonStreamParserWaitingForData,
	VGSBJsonStreamParserError,
} VGSBJsonStreamParserStatus;


/**
 @brief Delegate for interacting directly with the stream parser
 
 You will most likely find it much more convenient to implement the
 VGJsonStreamParserAdapterDelegate protocol instead.
 */
@protocol VGJsonStreamParserDelegate

/// Called when object start is found
- (void)parserFoundObjectStart:(VGJsonStreamParser*)parser;

/// Called when object key is found
- (void)parser:(VGJsonStreamParser*)parser foundObjectKey:(NSString*)key;

/// Called when object end is found
- (void)parserFoundObjectEnd:(VGJsonStreamParser*)parser;

/// Called when array start is found
- (void)parserFoundArrayStart:(VGJsonStreamParser*)parser;

/// Called when array end is found
- (void)parserFoundArrayEnd:(VGJsonStreamParser*)parser;

/// Called when a boolean value is found
- (void)parser:(VGJsonStreamParser*)parser foundBoolean:(BOOL)x;

/// Called when a null value is found
- (void)parserFoundNull:(VGJsonStreamParser*)parser;

/// Called when a number is found
- (void)parser:(VGJsonStreamParser*)parser foundNumber:(NSNumber*)num;

/// Called when a string is found
- (void)parser:(VGJsonStreamParser*)parser foundString:(NSString*)string;

@end


/**
 @brief Parse a stream of JSON data.
 
 Using this class directly you can reduce the apparent latency for each
 download/parse cycle of documents over a slow connection. You can start
 parsing *and return chunks of the parsed document* before the entire
 document is downloaded.
 
 Using this class is also useful to parse huge documents on disk
 bit by bit so you don't have to keep them all in memory. 
 
 @see VGJsonStreamParserAdapter for more information.
 
 @see @ref objc2json
 
 */
@interface VGJsonStreamParser : NSObject {
@private
	BOOL supportMultipleDocuments;
	id<VGJsonStreamParserDelegate> delegate;
	VGJsonTokeniser *tokeniser;
    NSMutableArray *stateStack;
	__weak VGJsonStreamParserState *state;
	NSUInteger maxDepth;
	NSString *error;
}

@property (nonatomic, assign) __weak VGJsonStreamParserState *state; // Private
@property (nonatomic, readonly, retain) NSMutableArray *stateStack; // Private

/**
 @brief Expect multiple documents separated by whitespace

 Normally the @p -parse: method returns VGSBJsonStreamParserComplete when it's found a complete JSON document.
 Attempting to parse any more data at that point is considered an error. ("Garbage after JSON".)
 
 If you set this property to true the parser will never return VGSBJsonStreamParserComplete. Rather,
 once an object is completed it will expect another object to immediately follow, separated
 only by (optional) whitespace.

 @see The TweetStream app in the Examples
 */
@property BOOL supportMultipleDocuments;

/**
 @brief Delegate to receive messages

 The object set here receives a series of messages as the parser breaks down the JSON stream
 into valid tokens.

 @note
 Usually this should be an instance of VGJsonStreamParserAdapter, but you can
 substitute your own implementation of the VGSBJsonStreamParserDelegate protocol if you need to. 
 */
@property (assign) id<VGJsonStreamParserDelegate> delegate;

/**
 @brief The max parse depth
 
 If the input is nested deeper than this the parser will halt parsing and return an error.

 Defaults to 32. 
 */
@property NSUInteger maxDepth;

/// Holds the error after VGSBJsonStreamParserError was returned
@property (copy) NSString *error;

/**
 @brief Parse some JSON
 
 The JSON is assumed to be UTF8 encoded. This can be a full JSON document, or a part of one.

 @param data An NSData object containing the next chunk of JSON

 @return 
 @li VGSBJsonStreamParserComplete if a full document was found
 @li VGSBJsonStreamParserWaitingForData if a partial document was found and more data is required to complete it
 @li VGSBJsonStreamParserError if an error occured. (See the error property for details in this case.)
 
 */
- (VGSBJsonStreamParserStatus)parse:(NSData*)data;

@end
