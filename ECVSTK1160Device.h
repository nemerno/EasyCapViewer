/* Copyright (c) 2009, Ben Trask
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY BEN TRASK ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL BEN TRASK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
// Models
#import "ECVCaptureDevice.h"

// STK1160
@class ECVSTK1160Device;
#import "stk11xx.h"

// Other Sources
#import "SAA711XChip.h"

enum {
	ECVSTK1160SVideoInput = 0,
	ECVSTK1160Composite1Input = 1,
	ECVSTK1160Composite2Input = 2,
	ECVSTK1160Composite3Input = 3,
	ECVSTK1160Composite4Input = 4
};
typedef NSUInteger ECVSTK1160VideoSource;
enum {
	ECVSTK1160Auto60HzFormat = 0,
	ECVSTK1160NTSCMFormat = 8,
	ECVSTK1160PAL60Format = 2,
	ECVSTK1160NTSC44360HzFormat = 6,
	ECVSTK1160PALMFormat = 3,
	ECVSTK1160NTSCJFormat = 9,

	ECVSTK1160Auto50HzFormat = 1,
	ECVSTK1160PALBGDHIFormat = 10,
	ECVSTK1160NTSC44350HzFormat = 7,
	ECVSTK1160PALNFormat = 4,
	ECVSTK1160NTSCNFormat = 5,
	ECVSTK1160SECAMFormat = 11,
};
typedef NSUInteger ECVSTK1160VideoFormat;

@interface ECVSTK1160Device : ECVCaptureDevice <ECVCaptureDeviceConfiguring, SAA711XDevice>
{
	@private
	ECVSTK1160VideoSource _videoSource;
	ECVSTK1160VideoFormat _videoFormat;
	SAA711XChip *_SAA711XChip;
}

@property(assign) ECVSTK1160VideoSource videoSource;
@property(assign) ECVSTK1160VideoFormat videoFormat;

@end