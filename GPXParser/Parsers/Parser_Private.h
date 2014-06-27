//
//  Parser_Private.h
//  ParseOSXStarterProject
//
//  Created by Andrea Cremaschi on 27/06/14.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "GPX.h"

#import "Fix.h"
#import "Track.h"
#import "Waypoint.h"

@interface Parser (PrivateProperties)
@property (nonatomic, strong) GPX *gpx;
@property (nonatomic, strong) NSMutableString *currentString;
@property (nonatomic, strong) Track *track;
@property (nonatomic, strong) Track *route;
@property (nonatomic, strong) Waypoint *waypoint;
@property (nonatomic, strong) Fix *fix;
@property NSError *error;
@end
