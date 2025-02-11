import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var btnSegment: UIButton!

    private var imageName = "deeplab.jpg"
    private var image : UIImage?
    private let imageHelper = UIImageHelper()

    private lazy var module: TorchModule = {
        if let filePath = Bundle.main.path(forResource:
            "deeplabv3_scripted", ofType: "pt"),
            let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Can't find the model file!")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        btnSegment.setTitle("Segment", for: .normal)
        image = UIImage(named: imageName)!
        imageView.image = image
    }

    @IBAction func doInfer(_ sender: Any) {
        btnSegment.isEnabled = false
        btnSegment.setTitle("Running the model...", for: .normal)
        let resizedImage = image!.resized(to: CGSize(width: 250, height: 250))
        guard let pixelBuffer = resizedImage.normalized() else {
            return
        }

        let w = Int32(resizedImage.size.width)
        let h = Int32(resizedImage.size.height)
        DispatchQueue.global().async {
            // UnsafeMutablePointer() doesn't guarantee that the converted pointer points to the memory that is still being allocated
            // So we create a new pointer and copy the &pixelBuffer's memory to where it points to
            let copiedBufferPtr = UnsafeMutablePointer<Float>.allocate(capacity: pixelBuffer.count)
            copiedBufferPtr.initialize(from: pixelBuffer, count: pixelBuffer.count)
            let buffer = self.module.segment(image: copiedBufferPtr, withWidth:w, withHeight: h)
            copiedBufferPtr.deallocate()
            DispatchQueue.main.async {
                self.imageView.image = self.imageHelper.convertRGBBuffer(toUIImage: buffer , withWidth: w, withHeight: h)
                self.btnSegment.isEnabled = true
                self.btnSegment.setTitle("Segment", for: .normal)
            }
        }
    }

    @IBAction func doRestart(_ sender: Any) {
        if imageName == "deeplab.jpg" {
            imageName = "dog.jpg"
        }
        else {
            imageName = "deeplab.jpg"
        }
        image = UIImage(named: imageName)!
        imageView.image = image
    }
}
