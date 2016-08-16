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
  UIImage * outputImage = [self processUsingPixels:inputImage];
  
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
  
    
   /*加上这段代码，图片变成了黑白色
    为了做到这点，你需要把每一个像素的红色，绿色，蓝色通道的值设定成三个通道原始颜色值的平均值，就像开始的时候输出幽灵图像所有像素亮度值那样
    
    */
//    for (NSUInteger j = 0; j < inputHeight; j++) {
//        for (NSUInteger i = 0; i < inputWidth; i++) {
//            UInt32 * currentPixel = inputPixels + (j * inputWidth) + i;
//            UInt32 color = *currentPixel;
//            
//            // Average of RGB = greyscale
//            UInt32 averageColor = (R(color) +     G(color) + B(color)) / 3.0;
//            
//            *currentPixel = RGBAMake(averageColor,     averageColor, averageColor, A(color));
//        } 
//    }
    
    
    
    
    
    
    
 
    //幽灵
    UIImage * ghostImage = [UIImage imageNamed:@"ghost"];
    CGImageRef ghostCGImage = [ghostImage CGImage];

    
    
    CGFloat ghostImageAspectRatio =     ghostImage.size.width /     ghostImage.size.height;
    NSInteger targetGhostWidth = inputWidth *     0.25;
    CGSize ghostSize =     CGSizeMake(targetGhostWidth, targetGhostWidth     / ghostImageAspectRatio);
    CGPoint ghostOrigin =     CGPointMake(inputWidth * 0.5, inputHeight *     0.2);
   // CGPoint ghostOrigin =     CGPointMake(0, 0);

  
    
    NSUInteger ghostBytesPerRow = bytesPerPixel *ghostSize.width;
    UInt32 * ghostPixels = (UInt32     *)calloc(ghostSize.width * ghostSize.height,     sizeof(UInt32));
    
    CGContextRef ghostContext =     CGBitmapContextCreate(ghostPixels,     ghostSize.width, ghostSize.height,
                                                          bitsPerComponent, ghostBytesPerRow, colorSpace,
                                                          kCGImageAlphaPremultipliedLast |     kCGBitmapByteOrder32Big);
    CGContextDrawImage(ghostContext,     CGRectMake(0, 0, ghostSize.width,     ghostSize.height),ghostCGImage);
    
    
    
    
    
    
    NSUInteger offsetPixelCountForInput = ghostOrigin.y * inputWidth + ghostOrigin.x;
   
    
    for (NSUInteger j = 0; j < ghostSize.height; j++) {
        for (NSUInteger i = 0; i < ghostSize.width; i++) {
            UInt32 * inputPixel = inputPixels + j * inputWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *inputPixel;
            
            
            
            UInt32 * ghostPixel = ghostPixels + j     * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            
            // Do some processing here
            CGFloat ghostAlpha = 0.99f * (A(ghostColor)     / 255.0);
            UInt32 newR = R(inputColor) * (1 -     ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 -     ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 -     ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            // Clamp, not really useful here :p
            newR = MAX(0,MIN(255, newR));
            newG = MAX(0,MIN(255, newG));
            newB = MAX(0,MIN(255, newB));
            
            *inputPixel = RGBAMake(newR, newG, newB,     A(inputColor));
        } 
    }
    
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGContextRelease(ghostContext);
    free(inputPixels);
    free(ghostPixels);
    
    
    
    CGImageRef newCGImage =     CGBitmapContextCreateImage(context);
    UIImage * processedImage = [UIImage     imageWithCGImage:newCGImage];
    
    return processedImage;
 // return inputImage;
}


@end
