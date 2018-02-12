//
//  Fix.m
//  GPX Reader
//
//  Created by Jelle Vandebeeck on 11/01/12.
//  Copyright (c) 2012 fousa. All rights reserved.
//

#import "Fix.h"

double const UnsetFixElevation = -DBL_MAX;

@implementation Fix
@synthesize latitude=_latitude;
@synthesize longitude=_longitude;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _elevation = UnsetFixElevation;
    }
    return self;
}
#pragma mark - Coordinate

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(_latitude, _longitude);
}

#pragma mark - String

- (NSString *)description {
    return [NSString stringWithFormat:@"<Fix (%f %f)>", _latitude, _longitude];
}

@end
