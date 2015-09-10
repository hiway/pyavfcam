// pyavfcam
// Simple video capture in OSX using AVFoundation
//
// 2015 dashesy

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#include <iostream>
#include "avf.h"
#include "../avf_api.h"

// A basic shim that just passes things to C++ instance
@interface AVCaptureDelegate : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate,
                                         AVCaptureFileOutputRecordingDelegate>
{
    CppAVFCam * m_pInstance; // What I am delegated for
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
  fromConnection:(AVCaptureConnection *)connection;

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
  didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
  fromConnections:(NSArray *)connections
  error:(NSError *)error

@end


@implementation AVCaptureDelegate

- (id)init
{
    [super init];
    m_pInstance = NULL;
    return self;
}


-(void)dealloc
{
    // TODO: see what needs to be de-allocated
    [super dealloc];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
  fromConnection:(AVCaptureConnection *)connection
{
    // TODO: implement for callback

    // Get a bitmap representation of the frame using CoreImage and Cocoa calls

    // Pass an actual reference to a custom Frame class up

}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
  didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
  fromConnections:(NSArray *)connections
  error:(NSError *)error
{
    m_pInstance->file_output_done(error != NULL)
}

@end

// Default constructor
CppAVFCam::CppAVFCam()
    : m_pObj(NULL),
      m_pSession(NULL), m_pDevice(NULL), m_pCapture(NULL),
      m_pVideoInput(NULL), m_pVideoFileOutput(NULL)
{
    std::cout << "   C++: creating default CppAVFCam at " << this << std::endl;
}

// copy-constructor
CppAVFCam::CppAVFCam(const CppAVFCam& other)
    : CppAVFCam(),
{
    std::cout << "   C++: copy constructing CppAVFCam at " << this << std::endl;
    // Shallow copy the member pointers
    m_pObj = other.m_pObj
    m_pSession = other.m_pSession
    m_pDevice = other.m_pDevice
    m_pCapture = other.m_pCapture
    m_pVideoInput = other.m_pVideoInput
    m_pVideoFileOutput = other.m_pVideoFileOutput

    // TODO: now deallocate other gracefully
}

// main constructor
CppAVFCam::CppAVFCam(bool sink_file, bool sink_callback, PyObject * pObj)
    : CppAVFCam()
{
    std::cout << "   C++: creating CppAVFCam at " << this << std::endl;

    m_pObj = pObj;
    if (m_pObj) {
        if (import_avf()) {
            std::cerr << "[c+]  error in import_avf!\n";
        } else {
            Py_XINCREF(m_obj);
        }
    }

    m_pCapture = [[AVCaptureDelegate alloc] init];
    m_pCapture->m_pInstance = this;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    //AVCaptureVideoDataOutput *video_buffer_output = NULL

    // TODO: option to select among cameras
    m_pDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (m_pDevice) {
        m_pSession = [[AVCaptureSession alloc] init];
        NSError *error = nil;
        NSLog(@"start      3");
        m_pVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:m_pDevice error:&error];
        if (m_pVideoInput)
            [m_pSession addInput:m_pVideoInput];

        if (sink_file)
            m_pVideoFileOutput = [[AVCaptureFileOutput alloc] init];

        if (m_pVideoFileOutput)
            [m_pSession addOutput:m_pVideoFileOutput];

//        if (sink_callback) {
//            video_buffer_output = [[AVCaptureVideoDataOutput alloc] init];
//            dispatch_queue_t videoQueue = dispatch_queue_create("videoQueue", NULL);
//            [video_buffer_output setSampleBufferDelegate:self queue:videoQueue];
//
//            video_buffer_output.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
//            video_buffer_output.alwaysDiscardsLateVideoFrames=YES;
//        }
//        if (video_buffer_output)
//            [m_pSession addOutput:video_buffer_output];

        // Start the AV session
        [m_pSession startRunning];
    }
    [pool drain];

    // Now raise if error detected above for RAII
}

// Destructor
CppAVFCam::~CppAVFCam()
{
    std::cout << "   C++: destroying CppAVFCam at " << this << std::endl;
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    if (m_pSession) {
        [m_pSession stopRunning];
        [m_pSession release];
        m_pSession = NULL;
    }
    if (m_pDevice) {
        [m_pDevice release];
        m_pDevice = NULL;
    }

    if (m_pCapture) {
        [m_pCapture release];
        m_pCapture = NULL;
    }

    if (m_pVideoInput) {
        [m_pVideoInput release];
        m_pVideoInput = NULL;
    }

    if (m_pVideoFileOutput) {
        [m_pVideoFileOutput release];
        m_pVideoFileOutput = NULL;
    }

    [pool drain];

    // decrease refcount to Python binding
    Py_XDECREF(m_pObj);
    m_pObj = NULL;
}

// Assignment operator
CppAVFCam & CppAVFCam::operator= (CppAVFCam other)
{
    swap(*this, other);

    return *this
}

void CppAVFCam::swap(CppAVFCam& first, CppAVFCam& second)
{
    // enable ADL (not necessary in our case, but good practice)
    using std::swap;

    // by swapping the members of two classes,
    // the two classes are effectively swapped
    swap(first.m_pObj, second.m_pObj);
    swap(first.m_pSession, second.m_pSession);
    swap(first.m_pDevice, second.m_pDevice);
    swap(first.m_pCapture, second.m_pCapture);
    swap(first.m_pVideoInput, second.m_pVideoInput);
    swap(first.m_pVideoFileOutput, second.m_pVideoFileOutput);
}

// Callback to Python
void CppAVFCam::file_output_done(bool error)
{
    if (m_pObj) {
        int overridden;
        PyObject * kwargs = Py_BuildValue("{}");
        PyObject * args = Py_BuildValue("(i)", error);

        // Call a virtual overload, if it exists
        cy_call_func(m_pObj, &overridden, (char*)__func__, args, kwargs);
        if (!overridden) {
            if (error)
                std::cout << "   error recording " << this << std::endl;
            else
                std::cout << "   done recording " << this << std::endl;

        }
        return;
    }
}

void CppAVFCam::set_settings(unsigned int width, unsigned int height, float fps)
{
    if (!m_pDevice)
        return

    if ( YES == [m_pDevice lockForConfiguration:NULL] ) {
        // should set these properties after output is added to session or it may be lost
        [m_pDevice setActiveVideoMinFrameDuration:CMTimeMake(1, self.fps)];
        [m_pDevice setActiveVideoMaxFrameDuration:CMTimeMake(1, self.fps)];
        [m_pDevice unlockForConfiguration];
    }
}

void CppAVFCam::record(std::string path, unsigned int duration)
{
    if (!m_pVideoFileOutput || !m_pCapture || !m_pSession)
        // TODO: raise error
        return

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    NSString* path_str = [NSString stringWithUTF8String:path.c_str()];

    NSURL *url = [NSURL fileURLWithPath:path_str];
    [m_pVideoFileOutput startRecordingToOutputFileURL:url recordingDelegate:m_pCapture];

    [pool drain];
}

void CppAVFCam::get_device_formats()
{
    if (!m_pDevice)
        return

    for(AVCaptureDeviceFormat *vFormat in [m_pDevice formats] )
    {
        CMFormatDescriptionRef description= vFormat.formatDescription;
        float max_fps = ((AVFrameRateRange*)[vFormat.videoSupportedFrameRateRanges objectAtIndex:0]).maxFrameRate;
        int format = CMFormatDescriptionGetMediaSubType(description);
    }
}

std::vector CppAVFCam::get_dimension()
{
    std::vector<unsigned int> dim
    if (!m_pVideoInput)
        // TODO: raise error
        return dim
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    NSArray* ports = m_pVideoInput.ports;
    CMFormatDescriptionRef format = [[ports objectAtIndex:0] formatDescription];
    CGSize s1 = CMVideoFormatDescriptionGetPresentationDimensions(format, YES, YES);

    dim.push_back((unsigned int)s1.width);
    dim.push_back((unsigned int)s1.height);

    [pool drain];

    return dim;
}
