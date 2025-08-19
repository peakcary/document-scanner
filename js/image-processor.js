class ImageProcessor {
    constructor() {
        this.worker = null;
        this.initWebWorker();
    }

    initWebWorker() {
        // 创建WebWorker用于图像处理
        const workerCode = `
            let cv;
            
            self.addEventListener('message', async function(e) {
                const { type, data } = e.data;
                
                try {
                    switch(type) {
                        case 'init':
                            // 加载OpenCV.js到Worker中
                            importScripts('https://cdnjs.cloudflare.com/ajax/libs/opencv.js/4.8.0/opencv.js');
                            cv = self.cv;
                            self.postMessage({ type: 'ready' });
                            break;
                            
                        case 'process':
                            const result = await processImage(data);
                            self.postMessage({ type: 'result', data: result });
                            break;
                            
                        case 'detectEdges':
                            const edges = await detectDocumentEdges(data);
                            self.postMessage({ type: 'edges', data: edges });
                            break;
                    }
                } catch (error) {
                    self.postMessage({ type: 'error', error: error.message });
                }
            });

            async function processImage(imageData) {
                // WebWorker中的图像处理逻辑
                return imageData; // 简化版本
            }

            async function detectDocumentEdges(imageData) {
                // 边缘检测逻辑
                return [[0, 0], [100, 0], [100, 100], [0, 100]]; // 示例坐标
            }
        `;

        const blob = new Blob([workerCode], { type: 'application/javascript' });
        this.worker = new Worker(URL.createObjectURL(blob));
        
        this.worker.postMessage({ type: 'init' });
        
        this.worker.addEventListener('message', (e) => {
            const { type, data, error } = e.data;
            
            if (type === 'ready') {
                console.log('WebWorker ready for image processing');
            } else if (type === 'error') {
                console.error('WebWorker error:', error);
            }
        });
    }

    // 压缩图片
    compressImage(file, maxWidth = 1920, quality = 0.8) {
        return new Promise((resolve) => {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            const img = new Image();

            img.onload = () => {
                // 计算新尺寸
                let { width, height } = img;
                if (width > maxWidth) {
                    height = (height * maxWidth) / width;
                    width = maxWidth;
                }

                canvas.width = width;
                canvas.height = height;
                
                // 绘制压缩后的图片
                ctx.drawImage(img, 0, 0, width, height);
                
                canvas.toBlob(resolve, 'image/jpeg', quality);
            };

            img.src = URL.createObjectURL(file);
        });
    }

    // 检测文档边缘
    detectDocumentEdges(imageCanvas) {
        if (typeof cv === 'undefined') {
            console.warn('OpenCV not loaded, using fallback edge detection');
            return this.fallbackEdgeDetection(imageCanvas);
        }

        try {
            const src = cv.imread(imageCanvas);
            const gray = new cv.Mat();
            const blurred = new cv.Mat();
            const edged = new cv.Mat();
            const hierarchy = new cv.Mat();
            const contours = new cv.MatVector();

            // 转为灰度图
            cv.cvtColor(src, gray, cv.COLOR_RGBA2GRAY);
            
            // 高斯模糊
            cv.GaussianBlur(gray, blurred, new cv.Size(5, 5), 0);
            
            // Canny边缘检测
            cv.Canny(blurred, edged, 75, 200);
            
            // 查找轮廓
            cv.findContours(edged, contours, hierarchy, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
            
            let maxArea = 0;
            let bestContour = null;
            
            // 找到最大的矩形轮廓
            for (let i = 0; i < contours.size(); i++) {
                const contour = contours.get(i);
                const area = cv.contourArea(contour);
                
                if (area > maxArea && area > 1000) {
                    const peri = cv.arcLength(contour, true);
                    const approx = new cv.Mat();
                    cv.approxPolyDP(contour, approx, 0.02 * peri, true);
                    
                    if (approx.total() === 4) {
                        maxArea = area;
                        bestContour = approx;
                    }
                    approx.delete();
                }
                contour.delete();
            }

            let corners = null;
            if (bestContour) {
                corners = [];
                for (let i = 0; i < bestContour.total(); i++) {
                    const point = bestContour.data32S;
                    corners.push([point[i * 2], point[i * 2 + 1]]);
                }
                bestContour.delete();
            }

            // 清理内存
            src.delete();
            gray.delete();
            blurred.delete();
            edged.delete();
            hierarchy.delete();
            contours.delete();

            return corners || this.fallbackEdgeDetection(imageCanvas);
            
        } catch (error) {
            console.error('OpenCV edge detection failed:', error);
            return this.fallbackEdgeDetection(imageCanvas);
        }
    }

    // 备用边缘检测
    fallbackEdgeDetection(canvas) {
        const { width, height } = canvas;
        const margin = Math.min(width, height) * 0.1;
        
        return [
            [margin, margin],                    // 左上
            [width - margin, margin],            // 右上
            [width - margin, height - margin],   // 右下
            [margin, height - margin]            // 左下
        ];
    }

    // 透视校正
    perspectiveTransform(canvas, corners) {
        if (typeof cv === 'undefined') {
            console.warn('OpenCV not loaded, skipping perspective transform');
            return canvas.toDataURL();
        }

        try {
            const src = cv.imread(canvas);
            const dst = new cv.Mat();
            
            // 计算目标尺寸
            const width = Math.max(
                this.distance(corners[0], corners[1]),
                this.distance(corners[2], corners[3])
            );
            const height = Math.max(
                this.distance(corners[0], corners[3]),
                this.distance(corners[1], corners[2])
            );

            // 源点和目标点
            const srcPoints = cv.matFromArray(4, 1, cv.CV_32FC2, [
                corners[0][0], corners[0][1],
                corners[1][0], corners[1][1],
                corners[2][0], corners[2][1],
                corners[3][0], corners[3][1]
            ]);

            const dstPoints = cv.matFromArray(4, 1, cv.CV_32FC2, [
                0, 0,
                width, 0,
                width, height,
                0, height
            ]);

            // 计算透视变换矩阵
            const M = cv.getPerspectiveTransform(srcPoints, dstPoints);
            
            // 应用变换
            cv.warpPerspective(src, dst, M, new cv.Size(width, height));
            
            // 输出到canvas
            const outputCanvas = document.createElement('canvas');
            cv.imshow(outputCanvas, dst);
            
            // 清理内存
            src.delete();
            dst.delete();
            srcPoints.delete();
            dstPoints.delete();
            M.delete();
            
            return outputCanvas.toDataURL();
            
        } catch (error) {
            console.error('Perspective transform failed:', error);
            return canvas.toDataURL();
        }
    }

    // 计算两点间距离
    distance(p1, p2) {
        return Math.sqrt((p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2);
    }

    // 图像增强
    enhanceImage(canvas) {
        if (typeof cv === 'undefined') {
            return this.fallbackEnhancement(canvas);
        }

        try {
            const src = cv.imread(canvas);
            const dst = new cv.Mat();
            const gray = new cv.Mat();
            
            // 转为灰度图
            cv.cvtColor(src, gray, cv.COLOR_RGBA2GRAY);
            
            // 自适应阈值处理
            cv.adaptiveThreshold(
                gray, dst, 255,
                cv.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv.THRESH_BINARY, 11, 2
            );
            
            // 形态学操作清理噪点
            const kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(3, 3));
            cv.morphologyEx(dst, dst, cv.MORPH_CLOSE, kernel);
            
            // 输出结果
            cv.imshow(canvas, dst);
            
            // 清理内存
            src.delete();
            dst.delete();
            gray.delete();
            kernel.delete();
            
            return canvas.toDataURL();
            
        } catch (error) {
            console.error('Image enhancement failed:', error);
            return this.fallbackEnhancement(canvas);
        }
    }

    // 备用图像增强
    fallbackEnhancement(canvas) {
        const ctx = canvas.getContext('2d');
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const data = imageData.data;
        
        // 简单的对比度和亮度调整
        const contrast = 1.3;
        const brightness = 10;
        
        for (let i = 0; i < data.length; i += 4) {
            // 转为灰度
            const gray = (data[i] + data[i + 1] + data[i + 2]) / 3;
            
            // 应用对比度和亮度
            let enhanced = contrast * gray + brightness;
            enhanced = Math.min(255, Math.max(0, enhanced));
            
            // 二值化效果
            enhanced = enhanced > 128 ? 255 : 0;
            
            data[i] = enhanced;     // Red
            data[i + 1] = enhanced; // Green
            data[i + 2] = enhanced; // Blue
        }
        
        ctx.putImageData(imageData, 0, 0);
        return canvas.toDataURL();
    }

    // 旋转图像
    rotateImage(canvas, angle) {
        const newCanvas = document.createElement('canvas');
        const ctx = newCanvas.getContext('2d');
        
        // 计算旋转后的尺寸
        const cos = Math.abs(Math.cos(angle));
        const sin = Math.abs(Math.sin(angle));
        const newWidth = canvas.height * sin + canvas.width * cos;
        const newHeight = canvas.height * cos + canvas.width * sin;
        
        newCanvas.width = newWidth;
        newCanvas.height = newHeight;
        
        // 移动到中心点
        ctx.translate(newWidth / 2, newHeight / 2);
        
        // 旋转
        ctx.rotate(angle);
        
        // 绘制图像
        ctx.drawImage(canvas, -canvas.width / 2, -canvas.height / 2);
        
        return newCanvas.toDataURL();
    }

    // OCR文字识别
    async recognizeText(canvas) {
        if (typeof Tesseract === 'undefined') {
            console.warn('Tesseract.js not loaded');
            return '';
        }

        try {
            const { data: { text } } = await Tesseract.recognize(canvas, 'chi_sim+eng', {
                logger: m => console.log(m)
            });
            return text;
        } catch (error) {
            console.error('OCR failed:', error);
            return '';
        }
    }

    // 生成ZIP文件
    async generateZip(processedImages) {
        if (typeof JSZip === 'undefined') {
            throw new Error('JSZip not loaded');
        }

        const zip = new JSZip();
        const imgFolder = zip.folder('scanned_documents');

        for (let i = 0; i < processedImages.length; i++) {
            const imageBytes = this.dataUrlToBytes(processedImages[i]);
            imgFolder.file(`document_${i + 1}.jpg`, imageBytes);
        }

        return await zip.generateAsync({ type: 'blob' });
    }

    // 数据URL转字节数组
    dataUrlToBytes(dataUrl) {
        const byteString = atob(dataUrl.split(',')[1]);
        const arrayBuffer = new ArrayBuffer(byteString.length);
        const uint8Array = new Uint8Array(arrayBuffer);
        
        for (let i = 0; i < byteString.length; i++) {
            uint8Array[i] = byteString.charCodeAt(i);
        }
        
        return arrayBuffer;
    }

    // 清理资源
    destroy() {
        if (this.worker) {
            this.worker.terminate();
            this.worker = null;
        }
    }
}