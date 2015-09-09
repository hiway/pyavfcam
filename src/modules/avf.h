// pyavfcam
// Simple video capture in OSX using AVFoundation
//
// 2015 dashesy

//--------------------------------------
// Keep the resemblance of a proper C++

class AVCaptureSession;
class AVCaptureDevice;
class AVCaptureDelegate;
class AVCaptureDeviceInput;
class AVCaptureFileOutput;

class CppAVFCam
{
private:
    AVCaptureSession * m_pSession;
    AVCaptureDevice * m_pDevice;              // Camera device
    AVCaptureDelegate * m_pCapture;           // Capture delegate
    AVCaptureDeviceInput * m_pVideoInput;
    AVCaptureFileOutput * m_pVideoFileOutput;

private:
    void file_output_done(bool error);
    void sample_buffer();

public:

    CppAVFCam();
    CppAVFCam(bool sink_file, bool sink_callback);
    CppAVFCam(const CppAVFCam& other);
    ~CppAVFCam();

    CppAVFCam & operator= (CppAVFCam other);
    friend void swap(CppAVFCam& first, CppAVFCam& second); // nothrow

    void set_settings(unsigned int width, unsigned int height, float fps);
    void record(std::string path);
    void get_device_formats();
    std::vector<unsigned int> get_dimension();
};