/* Copyright (c) 2012, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
#import "ECVCaptureDocument.h"

#import "ECVAudioDevice.h"
#import "ECVAudioTarget.h"
#import "ECVCaptureController.h"
#import "ECVController.h"
#import "ECVDebug.h"
#import "ECVReadWriteLock.h"

static NSString *const ECVAudioInputUIDKey = @"ECVAudioInputUID";
static NSString *const ECVAudioInputNone = @"ECVAudioInputNone";

@implementation ECVCaptureDocument

#pragma mark -ECVCaptureDocument

- (NSArray *)targets
{
	[_targetsLock readLock];
	NSArray *const targets = [[_targets copy] autorelease];
	[_targetsLock unlock];
	return targets;
}
- (void)addTarget:(id<ECVAVTarget> const)target
{
	[_targetsLock writeLock];
	[_targets addObject:target];
	[_targetsLock unlock];
}
- (void)removeTarget:(id<ECVAVTarget> const)target
{
	[_targetsLock writeLock];
	[_targets removeObjectIdenticalTo:target];
	[_targetsLock unlock];
}
- (ECVAudioTarget *)audioTarget
{
	return [[_audioTarget retain] autorelease];
}

#pragma mark -

- (ECVCaptureDevice *)videoDevice
{
	return [[_videoDevice retain] autorelease];
}
- (void)setVideoDevice:(ECVCaptureDevice *const)source
{
	if(source == _videoDevice) return;
	[_videoDevice release];
	_videoDevice = [source retain];
	[_videoDevice setCaptureDocument:self];
}
- (NSUserDefaults *)defaults
{
	return [_videoDevice defaults];
}

#pragma mark -

- (NSUInteger)pauseCount
{
	return _pauseCount;
}
- (BOOL)isPaused
{
	return !!_pauseCount;
}
- (void)setPaused:(BOOL const)flag
{
	NSParameterAssert(flag || 0 != _pauseCount);
	if(flag) {
		if(1 == ++_pauseCount) [self stop];
	} else {
		if(0 == --_pauseCount) [self play];
	}
}
- (BOOL)isPausedFromUI
{
	return _pausedFromUI;
}
- (void)setPausedFromUI:(BOOL const)flag
{
	if(flag == _pausedFromUI) return;
	_pausedFromUI = flag;
	[self setPaused:_pausedFromUI];
}

#pragma mark -

- (void)workspaceWillSleep:(NSNotification *const)aNotif
{
	// TODO: Do something.
//	[self setPausedFromUI:YES];
//	[self noteDeviceRemoved];
}

#pragma mark -

- (ECVAudioInput *)audioDevice
{
	if(!_audioDevice) {
		NSString *const UID = [[self defaults] objectForKey:ECVAudioInputUIDKey];
		if(!BTEqualObjects(ECVAudioInputNone, UID)) {
			if(UID) _audioDevice = [[ECVAudioInput deviceWithUID:UID] retain];
			if(!_audioDevice) _audioDevice = [[[self videoDevice] builtInAudioInput] retain];
			
		}
	}
	return [[_audioDevice retain] autorelease];
}
- (void)setAudioDevice:(ECVAudioInput *const)device
{
	if(!BTEqualObjects(device, _audioDevice)) {
		[self setPaused:YES];
		[_audioDevice release];
		_audioDevice = [device retain];
		[_audioTarget setInputBasicDescription:[[_audioDevice stream] basicDescription]];
		[self setPaused:NO];
	}
	if(BTEqualObjects([[self videoDevice] builtInAudioInput], device)) {
		[[self defaults] removeObjectForKey:ECVAudioInputUIDKey];
	} else if(device) {
		[[self defaults] setObject:[device UID] forKey:ECVAudioInputUIDKey];
	} else {
		[[self defaults] setObject:ECVAudioInputNone forKey:ECVAudioInputUIDKey];
	}
}

#pragma mark -ECVCaptureDocument<ECVVideoTarget>

- (void)play
{
	if(_audioDevice) [self addTarget:_audioTarget];
	[_videoDevice play];
	[_targets makeObjectsPerformSelector:@selector(play)];
	[[ECVController sharedController] noteCaptureDocumentStartedPlaying:self];
}
- (void)stop
{
	[[ECVController sharedController] noteCaptureDocumentStoppedPlaying:self];
	[_targets makeObjectsPerformSelector:@selector(stop)];
	[_videoDevice stop];
	[self removeTarget:_audioTarget];
}
- (void)pushVideoFrame:(ECVVideoFrame *const)frame
{
	if(!frame) return;
	[_targetsLock readLock];
	[_targets makeObjectsPerformSelector:@selector(pushVideoFrame:) withObject:frame];
	[_targetsLock unlock];
}
- (void)pushAudioBufferListValue:(NSValue *const)bufferListValue {}

#pragma mark -ECVCaptureDocument<ECVAudioDeviceDelegate>

- (void)audioInput:(ECVAudioInput *const)sender didReceiveBufferList:(AudioBufferList const *const)bufferList atTime:(AudioTimeStamp const *const)t
{
	if(sender != _audioDevice) return;
	[_targetsLock readLock];
	[_targets makeObjectsPerformSelector:@selector(pushAudioBufferListValue:) withObject:[NSValue valueWithPointer:bufferList]];
	[_targetsLock unlock];
}

#pragma mark -NSDocument

- (void)addWindowController:(NSWindowController *const)windowController
{
	[super addWindowController:windowController];
	[self addTarget:(id<ECVAVTarget>)windowController];
}
- (void)removeWindowController:(NSWindowController *const)windowController
{
	[super removeWindowController:windowController];
	[self removeTarget:(id<ECVAVTarget>)windowController];
}
- (void)makeWindowControllers
{
	[self addWindowController:[[[ECVCaptureController alloc] init] autorelease]];
}

#pragma mark -

- (NSString *)displayName
{
	return [_videoDevice name] ?: @"";
}
- (void)close
{
	[self setPausedFromUI:YES];
	[super close];
}

#pragma mark -NSObject

- (id)init
{
	if((self = [super init])) {
		// FIXME: The video device is not set at this point, so we can't read the defaults yet.

		_pauseCount = 1;
		_pausedFromUI = YES;

		_targetsLock = [[ECVReadWriteLock alloc] init];
		_targets = [[NSMutableArray alloc] init];
		_audioTarget = [[ECVAudioTarget alloc] init];
		[_audioTarget setCaptureDocument:self];

		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceWillSleep:) name:NSWorkspaceWillSleepNotification object:[NSWorkspace sharedWorkspace]];
	}
	return self;
}
- (void)dealloc
{
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];

	ECVConfigController *const config = [ECVConfigController sharedConfigController];
	if([config captureDocument] == self) [config setCaptureDocument:nil];

	[_targetsLock release];
	[_targets release];
	[_audioTarget release];

	[_videoDevice release];
	[_audioDevice release];

	[super dealloc];
}

@end
