//
//  ImageProcessor.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ImageProcessor.h"

@interface ImageProcessor ()

@end

@implementation ImageProcessor

+ (instancetype)sharedProcessor {
  static id sharedInstance = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  
  return sharedInstance;
}

#pragma mark - Public

- (void)processImage:(UIImage*)inputImage {
  UIImage * outputImage = [self processUsingCoreGraphics:inputImage];
  
  if ([self.delegate respondsToSelector:
       @selector(imageProcessorFinishedProcessingWithImage:)]) {
    [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
  }
}












#pragma mark - Private

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )




- (UIImage *)processUsingCoreGraphics:(UIImage*)input {
  
    CGRect imageRect = {CGPointZero,input.size};
    NSInteger inputWidth = CGRectGetWidth(imageRect);
    NSInteger inputHeight = CGRectGetHeight(imageRect);
  
    
    
    // 1) Calculate the location of Ghosty
    UIImage * ghostImage = [UIImage imageNamed:@"ghost.png"];
    CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height;
    NSInteger targetGhostWidth = inputWidth * 0.25;
    CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
    CGPoint ghostOrigin = CGPointMake(inputWidth * 0.5, inputHeight * 0.2);
    CGRect ghostRect = {ghostOrigin, ghostSize};
   
    
    
    
    // 2) Draw your image into the context.
    UIGraphicsBeginImageContext(input.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGAffineTransform flip = CGAffineTransformMakeScale(1.0, -1.0);
    CGAffineTransform flipThenShift = CGAffineTransformTranslate(flip,0,-inputHeight);
    CGContextConcatCTM(context, flipThenShift);
    
    // CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextDrawImage(context, imageRect, [input CGImage]);
   
    
    
    /*
     你也需要把混合模式设置为kCGBlendModeSourceAtop。
     这里为context设置混合模式是为了让它使用之前的相同的alpha混合公式。在设置完这些参数之后，翻转幽灵的坐标然后把它绘制在图像中。
     */

   CGContextSetBlendMode(context, kCGBlendModeSourceAtop);
    /*
     在绘制完图像后，你context的alpha值设为了0.5。这只会影响后面绘制的图像，
     */
    
    CGContextSetAlpha(context,0.5);
    //只对局部起作用的翻转
    CGRect transformedGhostRect = CGRectApplyAffineTransform(ghostRect, flipThenShift);
    CGContextDrawImage(context, transformedGhostRect, [ghostImage CGImage]);
      //CGContextDrawImage(context, ghostRect, [ghostImage CGImage]);
    
    
  
    // 3) Retrieve your processed image
    UIImage * imageWithGhost = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
   // return imageWithGhost;
    
    
/*加上这些画面变成黑白色*/
    // 4) Draw your image into a grayscale context
    /*
     为了把你的图像转换成黑白的，你将创建一个使用灰度（grayscale）色彩的新的CGContext。它将把所有你在context中绘制的图像转换成灰度的。
     因为你使用CGBitmapContextCreate()来创建了这个context，坐标则是以左下角为原点，你不需要翻转它来绘制CGImage。
     4) 绘制你的图像到一个灰度（grayscale）context中
     
     
     */

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    context = CGBitmapContextCreate(nil, inputWidth, inputHeight,
                                    8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaNone);
  
    
    CGContextDrawImage(context, imageRect, [imageWithGhost CGImage]);
    
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
   
    UIImage * finalImage = [UIImage imageWithCGImage:imageRef];
  
    
    
    // 5) Cleanup
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    return finalImage;

    }










- (UIImage *)processUsingPixels:(UIImage*)inputImage {
  
  // 1. Get the raw pixels of the image
  UInt32 * inputPixels;
  
  CGImageRef inputCGImage = [inputImage CGImage];
  NSUInteger inputWidth = CGImageGetWidth(inputCGImage);
  NSUInteger inputHeight = CGImageGetHeight(inputCGImage);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  NSUInteger bytesPerPixel = 4;
  NSUInteger bitsPerComponent = 8;
  
  NSUInteger inputBytesPerRow = bytesPerPixel * inputWidth;
  
  inputPixels = (UInt32 *)calloc(inputHeight * inputWidth, sizeof(UInt32));
  
  CGContextRef context = CGBitmapContextCreate(inputPixels, inputWidth, inputHeight,
                                               bitsPerComponent, inputBytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  
  CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputCGImage);
  
  // 2. Blend the ghost onto the image
  UIImage * ghostImage = [UIImage imageNamed:@"ghost"];
  CGImageRef ghostCGImage = [ghostImage CGImage];
  
  // 2.1 Calculate the size & position of the ghost
  CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height;
  NSInteger targetGhostWidth = inputWidth * 0.25;
  CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
  CGPoint ghostOrigin = CGPointMake(inputWidth * 0.5, inputHeight * 0.2);
  
  // 2.2 Scale & Get pixels of the ghost
  NSUInteger ghostBytesPerRow = bytesPerPixel * ghostSize.width;
  
  UInt32 * ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
  
  CGContextRef ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height,
                                                    bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  
  CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height),ghostCGImage);
  
  // 2.3 Blend each pixel
  NSUInteger offsetPixelCountForInput = ghostOrigin.y * inputWidth + ghostOrigin.x;
  for (NSUInteger j = 0; j < ghostSize.height; j++) {
    for (NSUInteger i = 0; i < ghostSize.width; i++) {
      UInt32 * inputPixel = inputPixels + j * inputWidth + i + offsetPixelCountForInput;
      UInt32 inputColor = *inputPixel;
      
      UInt32 * ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
      UInt32 ghostColor = *ghostPixel;
      
      // Blend the ghost with 50% alpha
      CGFloat ghostAlpha = 0.5f * (A(ghostColor) / 255.0);
      UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
      UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
      UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
      
      //Clamp, not really useful here :p
      newR = MAX(0,MIN(255, newR));
      newG = MAX(0,MIN(255, newG));
      newB = MAX(0,MIN(255, newB));
      
      *inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
    }
  }
  
  // 3. Convert the image to Black & White
  for (NSUInteger j = 0; j < inputHeight; j++) {
    for (NSUInteger i = 0; i < inputWidth; i++) {
      UInt32 * currentPixel = inputPixels + (j * inputWidth) + i;
      UInt32 color = *currentPixel;
      
      // Average of RGB = greyscale
      UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
      
      *currentPixel = RGBAMake(averageColor, averageColor, averageColor, A(color));
    }
  }

  // 4. Create a new UIImage
  CGImageRef newCGImage = CGBitmapContextCreateImage(context);
  UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
  
  // 5. Cleanup!
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(context);
  CGContextRelease(ghostContext);
  free(inputPixels);
  free(ghostPixels);
  
  return processedImage;
}
#undef RGBAMake
#undef R
#undef G
#undef B
#undef A
#undef Mask8

#pragma mark Helpers


@end
