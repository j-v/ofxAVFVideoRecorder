#pragma once
#ifndef _AVF_VIDEO_RECORDER_H
#define _AVF_VIDEO_RECORDER_H


#include <string>


using namespace std;

class ofxAVFVideoRecorder {
public:
    ofxAVFVideoRecorder();
    ~ofxAVFVideoRecorder();
    bool isRecording();
    void setup(string $filename, int $width, int $height, int $framerate); // TODO type, quality
    void writeRGBA(unsigned char *data); // TODO other data types?
    int setAudioFile(string filename);
    void finishMovie();
private:
//    CGImageRef getCGImageFromData(unsigned char *data);
//    CVPixelBufferRef pixelBufferFromCGImage(CGImageRef image);
    void addAudioToFileAtPath(string srcPath, string destPath);
    
    bool recording;
    string audioFile;
    int width;
    int height;
    int framerate;
    int frames;
    string filename;
    string tmp_filename;
    
//    AVAssetWriterInput * writerInput;
//    AVAssetWriter * videoWriter;
//    AVAssetWriterInputPixelBufferAdaptor * pixelBufferAdaptor;
//    dispatch_queue_t dispatchQueue;
    
    void * recorderData;
};

#endif