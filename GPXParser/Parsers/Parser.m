//
//  Parser.m
//  GPX Reader
//
//  Created by Jelle Vandebeeck on 16/02/12.
//  Copyright (c) 2012 10to1. All rights reserved.
//

#import "Parser.h"

#import <CoreLocation/CoreLocation.h>

@interface Parser () {
    Fix *_previousFix;
}
@property (nonatomic, strong) GPX *gpx;
@property (nonatomic, strong) NSMutableString *currentString;
@property (nonatomic, strong) Track *track;
@property (nonatomic, strong) Track *segment;
@property (nonatomic, strong) Track *route;
@property (nonatomic, strong) Waypoint *waypoint;
@property (nonatomic, strong) Fix *fix;
@property NSError *error;

- (void)parse:(NSData *)data completion:(void(^)(BOOL success, GPX *gpx))completionHandler;
- (void)generatePaths;
@end

@implementation Parser
@synthesize gpx=_gpx;
@synthesize currentString=_currentString;
@synthesize track=_track;
@synthesize route=_route;
@synthesize fix=_fix;
@synthesize waypoint=_waypoint;
@synthesize segment=_segment;

#pragma mark Initialization

+ (GPX*)parse:(NSData *)data error:(NSError**)error{
    return [[self new] parse:data error:error];
}

#pragma mark - Parsing

- (GPX*)parse:(NSData *)data error:(NSError**)error{
    
    NSXMLParser *_parser = [[NSXMLParser alloc] initWithData:data];
    [_parser setDelegate:self];
    [_parser setShouldProcessNamespaces:NO];
    [_parser setShouldReportNamespacePrefixes:NO];
    [_parser setShouldResolveExternalEntities:NO];
    [_parser parse];
    
    if (self.error && error) *error = self.error;
    return self.gpx;
}

#pragma mark - XML Parser

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if(!_currentString) self.currentString = [[NSMutableString alloc] init];
	
	[_currentString appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    self.error = parseError;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
    self.error = validError;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.gpx = [GPX new];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self generatePaths];
}

#pragma mark - Conversion

- (void)generatePathForTrack:(Track *)track
            increaseDistance:(BOOL)increaseDistance
           topLeftCoordinate:(CLLocationCoordinate2D *)_topLeftCoord
       bottomRightCoordinate:(CLLocationCoordinate2D *)_bottomRightCoord
                   hasRegion:(BOOL *)_hasRegion
{
    
    CLLocationCoordinate2D *_coordinates = malloc(sizeof(CLLocationCoordinate2D) *track.fixes.count);
    for(int i = 0; i < track.fixes.count; i++) {
        Fix *fix = [track.fixes objectAtIndex:i];
        CLLocationCoordinate2D _coordinate = [fix coordinate];
        _coordinates[i] = _coordinate;
        
        // Set map bounds
        if (_hasRegion != NULL)
        {
            if (!*_hasRegion) {
                *_topLeftCoord = _coordinate;
                *_bottomRightCoord = _coordinate;
                *_hasRegion = YES;
            } else {
                (*_topLeftCoord).longitude = fmin((*_topLeftCoord).longitude, _coordinate.longitude);
                (*_topLeftCoord).latitude = fmax((*_topLeftCoord).latitude, _coordinate.latitude);
                
                (*_bottomRightCoord).longitude = fmax((*_bottomRightCoord).longitude, _coordinate.longitude);
                (*_bottomRightCoord).latitude = fmin((*_bottomRightCoord).latitude, _coordinate.latitude);
            }
        }
        
        if (increaseDistance)
        {
            if (_previousFix) {
                static double RAD_PER_DEG = M_PI / 180.0;
                double Rkm = 6371;
                double dlon = _coordinate.longitude - _previousFix.coordinate.longitude;
                double dlat = _coordinate.latitude - _previousFix.coordinate.latitude;
                double dlonRad = dlon * RAD_PER_DEG;
                double dlatRad = dlat * RAD_PER_DEG;
                double lat1Rad = _previousFix.coordinate.latitude * RAD_PER_DEG;
                double lat2Rad = _coordinate.latitude * RAD_PER_DEG;
                double a = pow((sin(dlatRad / 2)), 2.0) + cos(lat1Rad) * cos(lat2Rad) * pow(sin(dlonRad / 2), 2.0);
                double c = 2 * atan2(sqrt(a), sqrt(1 - a));
                double distance = Rkm * c;
                if (isnan(distance)) distance = 0;
                _gpx.distance += distance;
            } else {
                _gpx.distance = 0;
            }
            _previousFix = fix;
        }
    }
    track.path = [MKPolyline polylineWithCoordinates:_coordinates count:track.fixes.count];
    track.shadowPath = [MKPolyline polylineWithCoordinates:_coordinates count:track.fixes.count];
    free(_coordinates);
    
    for (Track *segment in track.trackSegments)
    {
        [self generatePathForTrack:segment
                  increaseDistance:NO
                 topLeftCoordinate:NULL
             bottomRightCoordinate:NULL
                         hasRegion:NULL];
    }
}

- (void)generatePaths {
    CLLocationCoordinate2D _topLeftCoord;
    CLLocationCoordinate2D _bottomRightCoord;
    
    BOOL _hasRegion = NO;
    
    // Fill the tracks
    for (Track *track in _gpx.tracks) {
        
        [self generatePathForTrack:track
                  increaseDistance:YES
                 topLeftCoordinate:&_topLeftCoord
             bottomRightCoordinate:&_bottomRightCoord
                         hasRegion:&_hasRegion];
    }
    
    // Take waypoints into account
    for (int i = 0; i < _gpx.waypoints.count; i++) {
        Waypoint *waypoint = [_gpx.waypoints objectAtIndex:i];
        CLLocationCoordinate2D _coordinate = [waypoint coordinate];
        
        // Set map bounds
        if (!_hasRegion) {
            _topLeftCoord = _coordinate;
            _bottomRightCoord = _coordinate;
            _hasRegion = YES;
        } else {
            _topLeftCoord.longitude = fmin(_topLeftCoord.longitude, _coordinate.longitude);
            _topLeftCoord.latitude = fmax(_topLeftCoord.latitude, _coordinate.latitude);
            
            _bottomRightCoord.longitude = fmax(_bottomRightCoord.longitude, _coordinate.longitude);
            _bottomRightCoord.latitude = fmin(_bottomRightCoord.latitude, _coordinate.latitude);
        }
    }
    
    // Fill the routes
    for (Track *route in _gpx.routes) {
        
        [self generatePathForTrack:route
                  increaseDistance:NO
                 topLeftCoordinate:&_topLeftCoord
             bottomRightCoordinate:&_bottomRightCoord
                         hasRegion:&_hasRegion];
    }
    
    // Create the region
    MKCoordinateRegion _region = (MKCoordinateRegion) { kCLLocationCoordinate2DInvalid, MKCoordinateSpanMake(0, 0) };
    
    _region.center.latitude = _topLeftCoord.latitude - (_topLeftCoord.latitude - _bottomRightCoord.latitude) * 0.5;
    _region.center.longitude = _topLeftCoord.longitude + (_bottomRightCoord.longitude - _topLeftCoord.longitude) * 0.5;
    _region.span.latitudeDelta = fabs(_topLeftCoord.latitude - _bottomRightCoord.latitude);
    _region.span.longitudeDelta = fabs(_bottomRightCoord.longitude - _topLeftCoord.longitude);
    _gpx.region = _region;
}

@end
