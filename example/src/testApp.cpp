#include "testApp.h"
#include "ofxAVFVideoRecorder.h"

//--------------------------------------------------------------
void testApp::setup(){
    // Test code to generate video
    int width = 640;
	int height = 480;
	int framerate = 30;
	int num_frames = 120;
    
	ofxAVFVideoRecorder recorder;
	recorder.setup(ofToDataPath("test.mov"), width, height, framerate); // must end in .mov extension
	recorder.setAudioFile(ofToDataPath("audio.wav"));
    
	int arr_size = width*height*4;
    unsigned char *data = (unsigned char *)malloc(arr_size*sizeof(unsigned char)); 
    
    // make test pattern
    int base_q = 10;
    int q_amp = 600;
    int period = 60;
    for (int frame=0; frame < num_frames; frame++)
	{
		int q =  base_q + 2 * q_amp * (fabs(frame % (period *2) - period))/ ((float) period);
		int x_shift, y_shift, val;
		for(int y=0;y<height;y++) {
			for(int x=0;x<width;x++) {
				
				x_shift = x - width / 2 + frame;
				y_shift = y - height /2 + frame ;
				val = fabs(((x_shift * y_shift + frame) % q) * 255.0/(float)q);
				int linesize = width * 4;
				data[y * linesize + x*4] =   val ; //r
				data[y * linesize + x*4+1] = val ; //g
				data[y * linesize + x*4+2] = val ; //b
			}
		}
        
        recorder.writeRGBA(data); // write frame to video
	}
    
    free(data);
    
	recorder.finishMovie(); // save movie and add audio
}

//--------------------------------------------------------------
void testApp::update(){

}

//--------------------------------------------------------------
void testApp::draw(){

}

//--------------------------------------------------------------
void testApp::keyPressed(int key){

}

//--------------------------------------------------------------
void testApp::keyReleased(int key){

}

//--------------------------------------------------------------
void testApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void testApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void testApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void testApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void testApp::dragEvent(ofDragInfo dragInfo){ 

}