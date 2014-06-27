//
//  Parser.h
//  GPX Reader
//
//  Created by Jelle Vandebeeck on 16/02/12.
//  Copyright (c) 2012 10to1. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "GPX.h"

#import "Fix.h"
#import "Track.h"
#import "Waypoint.h"

@interface Parser : NSObject <NSXMLParserDelegate>

+ (GPX*)parse:(NSData *)data error:(NSError**)error;

@end