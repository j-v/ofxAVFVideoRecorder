// TODO Maybe use CVPixelBufferCreateWithBytes instead of this CGImage stuff

#include "AVFVideoRecorder.h"
//#import "Cocoa/Cocoa.h"
#import <AVFoundation/AVFoundation.h>

#include <math.h>


typedef struct _AVFVideoRecorderData {
    AVAssetWriterInput * writerInput;
    AVAssetWriter * videoWriter;
    AVAssetWriterInputPixelBufferAdaptor * pixelBufferAdaptor;
    dispatch_queue_t dispatchQueue;
    
    CGImageRef image;
    CVPixelBufferRef pixelBuffer;
    bool frameReady;
} AVFVideoRecorderData;

CGImageRef getCGImageFromData(unsigned char *data, int width, int height) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // supported pixel formats: https://developer.apple.com/library/mac/#documentation/graphicsimaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203
    CGContextRef bitmapContext = CGBitmapContextCreate(
                                                       data,
                                                       width,
                                                       height,
                                                       8, // bitsPerComponent
                                                       4*width, // bytesPerRow
                                                       colorSpace,
                                                       kCGImageAlphaNoneSkipLast);
    
    CFRelease(colorSpace);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
    return cgImage;
}

CVPixelBufferRef pixelBufferFromCGImage(CGImageRef image, int width, int height)
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
	// TODO pixel format
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                          height, kCVPixelFormatType_32ARGB, (CFDictionaryRef) options,
                                          &pxbuffer);
    //    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    //    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                 height, 8, 4*width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    //    NSParameterAssert(context);
    //CGAffineTransform frameTr
    //CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

ofxAVFVideoRecorder::ofxAVFVideoRecorder() {
	recording = false;
} 

ofxAVFVideoRecorder::~ofxAVFVideoRecorder() {
}

bool ofxAVFVideoRecorder::isRecording() {
	return recording;
} 

void ofxAVFVideoRecorder::setup(string $filename, int $width, int $height, int $framerate) {
	// TODO validate parameters
	width = $width;
	height = $height;
	framerate = $framerate;
	filename = $filename;
    tmp_filename = filename + ".tmp.mov";
	frames = 0;

	NSString * dest_file = [NSString stringWithUTF8String:tmp_filename.c_str()];
	unlink([dest_file UTF8String]);

	NSError *error = nil;
    
    recorderData = (void *)malloc(sizeof(AVFVideoRecorderData));
    // TODO filetype
    AVFVideoRecorderData * rd = (AVFVideoRecorderData *) recorderData;
    rd->image = nil;
    rd->pixelBuffer = nil;
    rd->frameReady = false;
    rd->videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:dest_file] fileType:AVFileTypeQuickTimeMovie															  error:&error];
    

//	// TODO fileType
//    videoWriter = (void *)malloc(sizeof(AVAssetWriter));
//    AVAssetWriter *aw = (AVAssetWriter *)videoWriter;
//	//aw = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:dest_file] fileType:AVFileTypeQuickTimeMovie															  error:&error];
//    [aw initWithURL:[NSURL fileURLWithPath:dest_file]
//        fileType:AVFileTypeQuickTimeMovie
//        error:&error];
//	//NSParameterAssert(videoWriter);
	
	// TODO Video codec
	NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   //AVVideoCodecH264, AVVideoCodecKey,
								   AVVideoCodecAppleProRes422, AVVideoCodecKey,
								   [NSNumber numberWithInt:width], AVVideoWidthKey,
								   [NSNumber numberWithInt:height], AVVideoHeightKey,
								   nil];
    rd->writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings ];
    rd->writerInput.expectsMediaDataInRealTime = YES;
//    writerInput = (void *)malloc(sizeof(AVAssetWriterInput));
//    AVAssetWriterInput *wi = ((AVAssetWriterInput *)writerInput);
//    //wi = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings ];
//    [wi initWithMediaType:AVMediaTypeVideo outputSettings:videoSettings ]; 
////	writerInput = (void*)[AVAssetWriterInput
////										assetWriterInputWithMediaType:AVMediaTypeVideo
////										outputSettings:videoSettings] ;
	
	// TODO pixel format type
	NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];

//	pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput	
//													  sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary] retain];
    rd->pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:rd->writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary] retain];
//    pixelBufferAdaptor = (void*)malloc(sizeof(AVAssetWriterInputPixelBufferAdaptor));
//    AVAssetWriterInputPixelBufferAdaptor * pba = (AVAssetWriterInputPixelBufferAdaptor*)pixelBufferAdaptor;
//    [pba initWithAssetWriterInput:wi sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    

//	NSParameterAssert(writerInput);
//	NSParameterAssert([videoWriter canAddInput:writerInput]);

	// TODO better error handling
	if ([rd->videoWriter canAddInput:rd->writerInput])

		NSLog(@"I can add this input");
	else
		NSLog(@"i can't add this input");
	[rd->videoWriter addInput:rd->writerInput];
	if(error)
		NSLog(@"error = %@", [error localizedDescription]);
	
	recording = true;

	rd->dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);

	// start a sesion
    [rd->videoWriter startWriting];
    [rd->videoWriter startSessionAtSourceTime:kCMTimeZero];
}

void ofxAVFVideoRecorder::writeRGBA(unsigned char *data) {
    static bool queue_created = false;
	if (recording)
	{
		
        AVFVideoRecorderData *  rd = (AVFVideoRecorderData *) recorderData;
		//CGImageRef  image = getCGImageFromData(data, width, height);
		//CVPixelBufferRef  buffer = pixelBufferFromCGImage(image, width, height);
        rd->image = getCGImageFromData(data, width, height);
		rd->pixelBuffer = pixelBufferFromCGImage(rd->image, width, height);
        rd->frameReady = true;
        //bool __block finished = false;

//        if (rd->pixelBufferAdaptor.assetWriterInput.isReadyForMoreMediaData)
//        {
//        if (![rd->pixelBufferAdaptor appendPixelBuffer:buffer
//                             withPresentationTime:CMTimeMake(frames, framerate)]);
//            NSLog(@"Failed to add frame"); // TODO handle better
//        }
//             else
//             NSLog(@"Failed to add frame - not ready"); // TODO handle better
//        if (buffer)
//            CFRelease(buffer);
//        CGImageRelease(image);
//        frames++;
		
//		if (buffer)
//		{
        if (!queue_created)
        {
            queue_created = true;
        
			[rd->writerInput requestMediaDataWhenReadyOnQueue:rd->dispatchQueue usingBlock:^{
                if (rd->frameReady)
                {
                while ([rd->writerInput isReadyForMoreMediaData])
                {
				if (![rd->pixelBufferAdaptor appendPixelBuffer:rd->pixelBuffer
                                      withPresentationTime:CMTimeMake(frames, framerate)])
				{
					// error adding frame
					NSLog(@"Failed to add frame"); // TODO handle better
				}
				else
				{
                    NSLog(@"Added frame %d", frames);
					frames++;
				}
				CFRelease(rd->pixelBuffer);
				
				//finished = true;
                    rd->frameReady = false;
                    //[rd->writerInput markAsFinished];
                    break;
                }
                }
                else
                    [NSThread sleepForTimeInterval:0.01];
			}];
            
        
		}
        
        
        while (rd->frameReady)
            [NSThread sleepForTimeInterval:0.01];
            //usleep(10000); // 10 ms
        CGImageRelease(rd->image);
//		else
//		{
//			// failed to create buffer TODO handle better
// 			CGImageRelease(image);
//		}
	}
	else
	{
		// TODO not ready to record
	}
}

int ofxAVFVideoRecorder::setAudioFile(string filename) {
	// TODO validate input?
	audioFile = filename;
}

void ofxAVFVideoRecorder::finishMovie() {
    AVFVideoRecorderData * rd = (AVFVideoRecorderData *) recorderData;
	[rd->writerInput markAsFinished];
	[rd->videoWriter finishWriting];
	[rd->videoWriter release];
    
	// Add audio
	addAudioToFileAtPath(tmp_filename, filename);
	// TODO delete tmp file?

}



void ofxAVFVideoRecorder::addAudioToFileAtPath(string srcPath, string destPath){
	// TODO check if audioFile has been set?

	NSError * error = nil;
    NSString *ns_srcPath = [NSString stringWithUTF8String:srcPath.c_str()];
	NSString *ns_destPath = [NSString stringWithUTF8String:destPath.c_str()];
	NSString *ns_audioPath = [NSString stringWithUTF8String:audioFile.c_str()];

    AVMutableComposition * composition = [AVMutableComposition composition];
    
    
    AVURLAsset * videoAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:ns_srcPath] options:nil];
    
    AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                preferredTrackID: kCMPersistentTrackID_Invalid];
    
	// Use duration of video -- audio would be shortened if longer
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero
                                     error:&error];
    
    CMTime audioStartTime = kCMTimeZero;
    //attach audio file
     
    AVURLAsset * urlAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:ns_audioPath] options:nil];
    
    AVAssetTrack * audioAssetTrack = [[urlAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                preferredTrackID: kCMPersistentTrackID_Invalid];
    
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,videoAsset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
    
	// TODO Export preset
    AVAssetExportSession* assetExport = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleProRes422LPCM];
    
	// TODO Output file type
    assetExport.outputFileType =AVFileTypeQuickTimeMovie;// @"com.apple.quicktime-movie";
    assetExport.outputURL = [NSURL fileURLWithPath:ns_destPath];
    
    bool __block done = false;
    NSLog(@"Exporting audio video");
    
	// Do the Export TODO Change logger
    [assetExport exportAsynchronouslyWithCompletionHandler:
     ^(void ) {
         switch (assetExport.status)
         {
             case AVAssetExportSessionStatusCompleted:
                 //                export complete
                 NSLog(@"Export Complete");
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"Export Failed");
                 NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                 //                export error (see exportSession.error)
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"Export Failed");
                 NSLog(@"ExportSessionError: %@", [assetExport.error localizedDescription]);
                 //                export cancelled  
                 break;
         }
         done = true;
         }];

    while (!done) sleep(1); // TODO could use usleep to sleep for milliseconds (#include <unistd.h>)
} 


