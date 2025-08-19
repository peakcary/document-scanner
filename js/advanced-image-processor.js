/**
 * 高级图像处理模块 - 实现类似WPS扫描的文档处理功能
 * 包含边缘检测、透视校正、画质增强、扫描风格等
 */

class AdvancedImageProcessor {
    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.originalImageData = null;
        this.processedImageData = null;
    }

    /**
     * 初始化处理器
     * @param {HTMLCanvasElement} canvas 
     */
    init(canvas) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
    }

    /**
     * 加载图像到画布
     * @param {HTMLImageElement|File} imageSource 
     */
    async loadImage(imageSource) {
        return new Promise((resolve, reject) => {
            const img = new Image();
            
            img.onload = () => {
                // 设置画布尺寸
                this.canvas.width = img.width;
                this.canvas.height = img.height;
                
                // 绘制原始图像
                this.ctx.drawImage(img, 0, 0);
                
                // 保存原始图像数据
                this.originalImageData = this.ctx.getImageData(0, 0, img.width, img.height);
                this.processedImageData = new ImageData(
                    new Uint8ClampedArray(this.originalImageData.data),
                    img.width,
                    img.height
                );
                
                resolve(img);
            };
            
            img.onerror = reject;
            
            if (imageSource instanceof File) {
                const reader = new FileReader();
                reader.onload = (e) => img.src = e.target.result;
                reader.readAsDataURL(imageSource);
            } else {
                img.src = imageSource.src;
            }
        });
    }

    /**
     * Canny边缘检测算法
     * @param {number} lowThreshold 低阈值
     * @param {number} highThreshold 高阈值
     */
    cannyEdgeDetection(lowThreshold = 50, highThreshold = 100) {
        const data = this.processedImageData.data;
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        
        // 1. 高斯模糊降噪
        const blurred = this.gaussianBlur(this.processedImageData, 1.4);
        
        // 2. 计算梯度
        const gradients = this.computeGradients(blurred);
        
        // 3. 非极大值抑制
        const suppressed = this.nonMaxSuppression(gradients);
        
        // 4. 双阈值检测
        const edges = this.doubleThreshold(suppressed, lowThreshold, highThreshold);
        
        // 5. 边缘连接
        const connected = this.edgeTracking(edges);
        
        return connected;
    }

    /**
     * 高斯模糊
     */
    gaussianBlur(imageData, sigma) {
        const data = new Uint8ClampedArray(imageData.data);
        const width = imageData.width;
        const height = imageData.height;
        
        // 生成高斯核
        const kernelSize = Math.ceil(sigma * 3) * 2 + 1;
        const kernel = this.generateGaussianKernel(kernelSize, sigma);
        
        // 水平模糊
        const horizontalBlur = this.convolve(data, width, height, kernel, true);
        
        // 垂直模糊
        const verticalBlur = this.convolve(horizontalBlur, width, height, kernel, false);
        
        return new ImageData(verticalBlur, width, height);
    }

    /**
     * 生成高斯核
     */
    generateGaussianKernel(size, sigma) {
        const kernel = [];
        const center = Math.floor(size / 2);
        let sum = 0;
        
        for (let i = 0; i < size; i++) {
            const x = i - center;
            const value = Math.exp(-(x * x) / (2 * sigma * sigma));
            kernel[i] = value;
            sum += value;
        }
        
        // 归一化
        for (let i = 0; i < size; i++) {
            kernel[i] /= sum;
        }
        
        return kernel;
    }

    /**
     * 卷积操作
     */
    convolve(data, width, height, kernel, horizontal) {
        const result = new Uint8ClampedArray(data.length);
        const kernelSize = kernel.length;
        const radius = Math.floor(kernelSize / 2);
        
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                for (let c = 0; c < 4; c++) {
                    let sum = 0;
                    
                    for (let i = 0; i < kernelSize; i++) {
                        let sampleX, sampleY;
                        
                        if (horizontal) {
                            sampleX = Math.max(0, Math.min(width - 1, x + i - radius));
                            sampleY = y;
                        } else {
                            sampleX = x;
                            sampleY = Math.max(0, Math.min(height - 1, y + i - radius));
                        }
                        
                        const index = (sampleY * width + sampleX) * 4 + c;
                        sum += data[index] * kernel[i];
                    }
                    
                    const targetIndex = (y * width + x) * 4 + c;
                    result[targetIndex] = Math.round(sum);
                }
            }
        }
        
        return result;
    }

    /**
     * 计算梯度
     */
    computeGradients(imageData) {
        const data = imageData.data;
        const width = imageData.width;
        const height = imageData.height;
        
        const gradients = [];
        
        // Sobel算子
        const sobelX = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]];
        const sobelY = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]];
        
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                let gx = 0, gy = 0;
                
                // 计算梯度
                for (let dy = -1; dy <= 1; dy++) {
                    for (let dx = -1; dx <= 1; dx++) {
                        const index = ((y + dy) * width + (x + dx)) * 4;
                        const gray = (data[index] + data[index + 1] + data[index + 2]) / 3;
                        
                        gx += gray * sobelX[dy + 1][dx + 1];
                        gy += gray * sobelY[dy + 1][dx + 1];
                    }
                }
                
                const magnitude = Math.sqrt(gx * gx + gy * gy);
                const direction = Math.atan2(gy, gx);
                
                gradients.push({
                    x, y, magnitude, direction, gx, gy
                });
            }
        }
        
        return gradients;
    }

    /**
     * 霍夫变换检测直线
     */
    houghLineTransform(edges, threshold = 50) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        
        // 霍夫空间参数
        const maxRho = Math.sqrt(width * width + height * height);
        const rhoResolution = 1;
        const thetaResolution = Math.PI / 180;
        
        const numRho = Math.ceil(2 * maxRho / rhoResolution);
        const numTheta = Math.ceil(Math.PI / thetaResolution);
        
        // 累加器数组
        const accumulator = Array(numRho).fill(null).map(() => Array(numTheta).fill(0));
        
        // 对每个边缘点进行霍夫变换
        edges.forEach(point => {
            const x = point.x;
            const y = point.y;
            
            for (let thetaIdx = 0; thetaIdx < numTheta; thetaIdx++) {
                const theta = thetaIdx * thetaResolution;
                const rho = x * Math.cos(theta) + y * Math.sin(theta);
                const rhoIdx = Math.round((rho + maxRho) / rhoResolution);
                
                if (rhoIdx >= 0 && rhoIdx < numRho) {
                    accumulator[rhoIdx][thetaIdx]++;
                }
            }
        });
        
        // 找到峰值（直线）
        const lines = [];
        for (let rhoIdx = 0; rhoIdx < numRho; rhoIdx++) {
            for (let thetaIdx = 0; thetaIdx < numTheta; thetaIdx++) {
                if (accumulator[rhoIdx][thetaIdx] > threshold) {
                    const rho = (rhoIdx * rhoResolution) - maxRho;
                    const theta = thetaIdx * thetaResolution;
                    lines.push({ rho, theta, votes: accumulator[rhoIdx][thetaIdx] });
                }
            }
        }
        
        return lines.sort((a, b) => b.votes - a.votes);
    }

    /**
     * 自动检测文档边界
     */
    detectDocumentCorners() {
        // 1. 边缘检测
        const edges = this.cannyEdgeDetection(50, 150);
        
        // 2. 霍夫直线检测
        const lines = this.houghLineTransform(edges, 80);
        
        // 3. 筛选出最有可能的4条边
        const documentLines = this.filterDocumentLines(lines);
        
        // 4. 计算交点得到4个角点
        const corners = this.computeIntersections(documentLines);
        
        // 5. 排序角点（左上、右上、右下、左下）
        const sortedCorners = this.sortCorners(corners);
        
        return sortedCorners;
    }

    /**
     * 筛选文档边缘直线
     */
    filterDocumentLines(lines) {
        if (lines.length < 4) return lines;
        
        // 按角度分组，找出接近水平和垂直的直线
        const horizontalLines = [];
        const verticalLines = [];
        
        lines.forEach(line => {
            const angle = line.theta * 180 / Math.PI;
            if (Math.abs(angle) < 45 || Math.abs(angle - 180) < 45) {
                horizontalLines.push(line);
            } else if (Math.abs(angle - 90) < 45) {
                verticalLines.push(line);
            }
        });
        
        // 选择最强的2条水平线和2条垂直线
        const selectedLines = [];
        selectedLines.push(...horizontalLines.slice(0, 2));
        selectedLines.push(...verticalLines.slice(0, 2));
        
        return selectedLines;
    }

    /**
     * 计算直线交点
     */
    computeIntersections(lines) {
        const corners = [];
        
        for (let i = 0; i < lines.length; i++) {
            for (let j = i + 1; j < lines.length; j++) {
                const intersection = this.lineIntersection(lines[i], lines[j]);
                if (intersection) {
                    corners.push(intersection);
                }
            }
        }
        
        return corners;
    }

    /**
     * 两直线交点计算
     */
    lineIntersection(line1, line2) {
        const rho1 = line1.rho, theta1 = line1.theta;
        const rho2 = line2.rho, theta2 = line2.theta;
        
        const cos1 = Math.cos(theta1), sin1 = Math.sin(theta1);
        const cos2 = Math.cos(theta2), sin2 = Math.sin(theta2);
        
        const det = cos1 * sin2 - sin1 * cos2;
        if (Math.abs(det) < 1e-10) return null; // 平行线
        
        const x = (sin2 * rho1 - sin1 * rho2) / det;
        const y = (cos1 * rho2 - cos2 * rho1) / det;
        
        return { x, y };
    }

    /**
     * 排序角点
     */
    sortCorners(corners) {
        if (corners.length !== 4) {
            // 如果检测不到4个角点，使用默认值
            const width = this.processedImageData.width;
            const height = this.processedImageData.height;
            return [
                { x: 0, y: 0 },
                { x: width, y: 0 },
                { x: width, y: height },
                { x: 0, y: height }
            ];
        }
        
        // 计算中心点
        const centerX = corners.reduce((sum, p) => sum + p.x, 0) / 4;
        const centerY = corners.reduce((sum, p) => sum + p.y, 0) / 4;
        
        // 按象限排序
        const topLeft = corners.filter(p => p.x < centerX && p.y < centerY)[0];
        const topRight = corners.filter(p => p.x > centerX && p.y < centerY)[0];
        const bottomRight = corners.filter(p => p.x > centerX && p.y > centerY)[0];
        const bottomLeft = corners.filter(p => p.x < centerX && p.y > centerY)[0];
        
        return [topLeft, topRight, bottomRight, bottomLeft].filter(Boolean);
    }

    /**
     * 透视校正
     */
    perspectiveCorrection(corners, outputWidth = 800, outputHeight = 1000) {
        // 目标矩形角点
        const destCorners = [
            { x: 0, y: 0 },
            { x: outputWidth, y: 0 },
            { x: outputWidth, y: outputHeight },
            { x: 0, y: outputHeight }
        ];
        
        // 计算透视变换矩阵
        const transformMatrix = this.computePerspectiveMatrix(corners, destCorners);
        
        // 应用透视变换
        const correctedCanvas = document.createElement('canvas');
        correctedCanvas.width = outputWidth;
        correctedCanvas.height = outputHeight;
        const correctedCtx = correctedCanvas.getContext('2d');
        
        this.applyPerspectiveTransform(correctedCtx, transformMatrix, outputWidth, outputHeight);
        
        return correctedCanvas;
    }

    /**
     * 计算透视变换矩阵
     */
    computePerspectiveMatrix(srcCorners, destCorners) {
        // 构建线性方程组 Ax = b
        const A = [];
        const b = [];
        
        for (let i = 0; i < 4; i++) {
            const src = srcCorners[i];
            const dest = destCorners[i];
            
            A.push([src.x, src.y, 1, 0, 0, 0, -dest.x * src.x, -dest.x * src.y]);
            A.push([0, 0, 0, src.x, src.y, 1, -dest.y * src.x, -dest.y * src.y]);
            
            b.push(dest.x);
            b.push(dest.y);
        }
        
        // 求解线性方程组（简化实现）
        const h = this.solveLinearSystem(A, b);
        h.push(1); // h8 = 1
        
        return h;
    }

    /**
     * 应用透视变换
     */
    applyPerspectiveTransform(destCtx, matrix, width, height) {
        const srcImageData = this.processedImageData;
        const destImageData = destCtx.createImageData(width, height);
        
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                // 反向映射
                const srcPoint = this.applyInversePerspective(x, y, matrix);
                
                if (srcPoint.x >= 0 && srcPoint.x < srcImageData.width &&
                    srcPoint.y >= 0 && srcPoint.y < srcImageData.height) {
                    
                    // 双线性插值
                    const color = this.bilinearInterpolation(srcImageData, srcPoint.x, srcPoint.y);
                    
                    const destIndex = (y * width + x) * 4;
                    destImageData.data[destIndex] = color.r;
                    destImageData.data[destIndex + 1] = color.g;
                    destImageData.data[destIndex + 2] = color.b;
                    destImageData.data[destIndex + 3] = 255;
                }
            }
        }
        
        destCtx.putImageData(destImageData, 0, 0);
    }

    /**
     * 扫描风格处理
     */
    applyScanningStyles(style = 'enhanced') {
        const styles = {
            'original': () => this.originalImageData,
            'grayscale': () => this.applyGrayscale(),
            'blackwhite': () => this.applyBlackWhite(),
            'enhanced': () => this.applyEnhanced(),
            'magazine': () => this.applyMagazineStyle(),
            'whiteboard': () => this.applyWhiteboardStyle()
        };
        
        const processedData = styles[style] ? styles[style]() : styles['enhanced']();
        
        this.ctx.putImageData(processedData, 0, 0);
        return processedData;
    }

    /**
     * 灰度处理
     */
    applyGrayscale() {
        const data = new Uint8ClampedArray(this.processedImageData.data);
        
        for (let i = 0; i < data.length; i += 4) {
            const gray = data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114;
            data[i] = gray;
            data[i + 1] = gray;
            data[i + 2] = gray;
        }
        
        return new ImageData(data, this.processedImageData.width, this.processedImageData.height);
    }

    /**
     * 黑白二值化处理
     */
    applyBlackWhite(threshold = 128) {
        const grayscale = this.applyGrayscale();
        const data = new Uint8ClampedArray(grayscale.data);
        
        // 自适应阈值
        const adaptiveThreshold = this.calculateAdaptiveThreshold(grayscale);
        
        for (let i = 0; i < data.length; i += 4) {
            const gray = data[i];
            const binaryValue = gray > adaptiveThreshold ? 255 : 0;
            data[i] = binaryValue;
            data[i + 1] = binaryValue;
            data[i + 2] = binaryValue;
        }
        
        return new ImageData(data, this.processedImageData.width, this.processedImageData.height);
    }

    /**
     * 增强模式 - 提升对比度和清晰度
     */
    applyEnhanced() {
        let data = new Uint8ClampedArray(this.processedImageData.data);
        
        // 1. 直方图均衡化
        data = this.histogramEqualization(data);
        
        // 2. 对比度增强
        data = this.enhanceContrast(data, 1.2);
        
        // 3. 锐化
        data = this.sharpen(data);
        
        // 4. 去噪
        data = this.denoise(data);
        
        return new ImageData(data, this.processedImageData.width, this.processedImageData.height);
    }

    /**
     * 直方图均衡化
     */
    histogramEqualization(data) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        const totalPixels = width * height;
        
        // 计算直方图
        const histogram = new Array(256).fill(0);
        for (let i = 0; i < data.length; i += 4) {
            const gray = Math.round(data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114);
            histogram[gray]++;
        }
        
        // 计算累积分布函数
        const cdf = new Array(256);
        cdf[0] = histogram[0];
        for (let i = 1; i < 256; i++) {
            cdf[i] = cdf[i - 1] + histogram[i];
        }
        
        // 归一化
        const result = new Uint8ClampedArray(data.length);
        for (let i = 0; i < data.length; i += 4) {
            const gray = Math.round(data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114);
            const newGray = Math.round((cdf[gray] / totalPixels) * 255);
            
            // 保持彩色信息的比例
            const ratio = newGray / (gray || 1);
            result[i] = Math.min(255, data[i] * ratio);
            result[i + 1] = Math.min(255, data[i + 1] * ratio);
            result[i + 2] = Math.min(255, data[i + 2] * ratio);
            result[i + 3] = data[i + 3];
        }
        
        return result;
    }

    /**
     * 对比度增强
     */
    enhanceContrast(data, factor = 1.2) {
        const result = new Uint8ClampedArray(data.length);
        
        for (let i = 0; i < data.length; i += 4) {
            result[i] = Math.min(255, Math.max(0, (data[i] - 128) * factor + 128));
            result[i + 1] = Math.min(255, Math.max(0, (data[i + 1] - 128) * factor + 128));
            result[i + 2] = Math.min(255, Math.max(0, (data[i + 2] - 128) * factor + 128));
            result[i + 3] = data[i + 3];
        }
        
        return result;
    }

    /**
     * 锐化处理
     */
    sharpen(data) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        const result = new Uint8ClampedArray(data.length);
        
        // 锐化核
        const kernel = [
            [0, -1, 0],
            [-1, 5, -1],
            [0, -1, 0]
        ];
        
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                for (let c = 0; c < 3; c++) {
                    let sum = 0;
                    
                    for (let ky = -1; ky <= 1; ky++) {
                        for (let kx = -1; kx <= 1; kx++) {
                            const index = ((y + ky) * width + (x + kx)) * 4 + c;
                            sum += data[index] * kernel[ky + 1][kx + 1];
                        }
                    }
                    
                    const targetIndex = (y * width + x) * 4 + c;
                    result[targetIndex] = Math.min(255, Math.max(0, sum));
                }
                
                const alphaIndex = (y * width + x) * 4 + 3;
                result[alphaIndex] = data[alphaIndex];
            }
        }
        
        return result;
    }

    /**
     * 去噪处理
     */
    denoise(data) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        const result = new Uint8ClampedArray(data.length);
        
        // 中值滤波去噪
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                for (let c = 0; c < 3; c++) {
                    const neighbors = [];
                    
                    for (let dy = -1; dy <= 1; dy++) {
                        for (let dx = -1; dx <= 1; dx++) {
                            const index = ((y + dy) * width + (x + dx)) * 4 + c;
                            neighbors.push(data[index]);
                        }
                    }
                    
                    neighbors.sort((a, b) => a - b);
                    const median = neighbors[Math.floor(neighbors.length / 2)];
                    
                    const targetIndex = (y * width + x) * 4 + c;
                    result[targetIndex] = median;
                }
                
                const alphaIndex = (y * width + x) * 4 + 3;
                result[alphaIndex] = data[alphaIndex];
            }
        }
        
        return result;
    }

    /**
     * 自适应阈值计算
     */
    calculateAdaptiveThreshold(imageData) {
        const data = imageData.data;
        let sum = 0;
        let count = 0;
        
        for (let i = 0; i < data.length; i += 4) {
            sum += data[i];
            count++;
        }
        
        return sum / count;
    }

    /**
     * 获取处理后的图像
     */
    getProcessedImage() {
        return this.canvas.toDataURL('image/jpeg', 0.9);
    }

    /**
     * 重置到原始图像
     */
    reset() {
        if (this.originalImageData) {
            this.ctx.putImageData(this.originalImageData, 0, 0);
            this.processedImageData = new ImageData(
                new Uint8ClampedArray(this.originalImageData.data),
                this.originalImageData.width,
                this.originalImageData.height
            );
        }
    }

    // 辅助方法 - 线性方程组求解（高斯消元法）
    solveLinearSystem(A, b) {
        const n = A.length;
        const augmented = A.map((row, i) => [...row, b[i]]);
        
        // 前向消元
        for (let i = 0; i < n; i++) {
            // 找到主元
            let maxRow = i;
            for (let k = i + 1; k < n; k++) {
                if (Math.abs(augmented[k][i]) > Math.abs(augmented[maxRow][i])) {
                    maxRow = k;
                }
            }
            
            // 交换行
            [augmented[i], augmented[maxRow]] = [augmented[maxRow], augmented[i]];
            
            // 消元
            for (let k = i + 1; k < n; k++) {
                if (Math.abs(augmented[i][i]) < 1e-10) continue;
                const factor = augmented[k][i] / augmented[i][i];
                for (let j = i; j < n + 1; j++) {
                    augmented[k][j] -= factor * augmented[i][j];
                }
            }
        }
        
        // 回代求解
        const x = new Array(n);
        for (let i = n - 1; i >= 0; i--) {
            x[i] = augmented[i][n];
            for (let j = i + 1; j < n; j++) {
                x[i] -= augmented[i][j] * x[j];
            }
            if (Math.abs(augmented[i][i]) > 1e-10) {
                x[i] /= augmented[i][i];
            }
        }
        
        return x;
    }

    applyInversePerspective(x, y, matrix) {
        // 逆透视变换：从目标坐标映射回源坐标
        const h = matrix;
        const denominator = h[6] * x + h[7] * y + 1;
        
        if (Math.abs(denominator) < 1e-10) {
            return { x: 0, y: 0 };
        }
        
        const srcX = (h[0] * x + h[1] * y + h[2]) / denominator;
        const srcY = (h[3] * x + h[4] * y + h[5]) / denominator;
        
        return { x: srcX, y: srcY };
    }

    bilinearInterpolation(imageData, x, y) {
        // 双线性插值获取平滑的像素值
        const x1 = Math.floor(x);
        const y1 = Math.floor(y);
        const x2 = Math.min(x1 + 1, imageData.width - 1);
        const y2 = Math.min(y1 + 1, imageData.height - 1);
        
        const wx = x - x1;
        const wy = y - y1;
        
        // 获取四个邻近像素
        const getPixel = (px, py) => {
            if (px < 0 || px >= imageData.width || py < 0 || py >= imageData.height) {
                return { r: 0, g: 0, b: 0 };
            }
            const idx = (py * imageData.width + px) * 4;
            return {
                r: imageData.data[idx],
                g: imageData.data[idx + 1],
                b: imageData.data[idx + 2]
            };
        };
        
        const p1 = getPixel(x1, y1);
        const p2 = getPixel(x2, y1);
        const p3 = getPixel(x1, y2);
        const p4 = getPixel(x2, y2);
        
        // 双线性插值计算
        const r = (1 - wx) * (1 - wy) * p1.r + wx * (1 - wy) * p2.r + 
                 (1 - wx) * wy * p3.r + wx * wy * p4.r;
        const g = (1 - wx) * (1 - wy) * p1.g + wx * (1 - wy) * p2.g + 
                 (1 - wx) * wy * p3.g + wx * wy * p4.g;
        const b = (1 - wx) * (1 - wy) * p1.b + wx * (1 - wy) * p2.b + 
                 (1 - wx) * wy * p3.b + wx * wy * p4.b;
        
        return {
            r: Math.round(Math.max(0, Math.min(255, r))),
            g: Math.round(Math.max(0, Math.min(255, g))),
            b: Math.round(Math.max(0, Math.min(255, b)))
        };
    }

    // 非极大值抑制 - Canny边缘检测的关键步骤
    nonMaxSuppression(gradients) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        const suppressed = [];
        
        // 创建梯度强度矩阵
        const magnitudes = Array(height).fill().map(() => Array(width).fill(0));
        const directions = Array(height).fill().map(() => Array(width).fill(0));
        
        gradients.forEach(grad => {
            magnitudes[grad.y][grad.x] = grad.magnitude;
            directions[grad.y][grad.x] = grad.direction;
        });
        
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                const angle = directions[y][x];
                const mag = magnitudes[y][x];
                
                // 确定梯度方向的邻近像素
                let neighbor1, neighbor2;
                const angleInDegrees = (angle * 180 / Math.PI + 180) % 180;
                
                if (angleInDegrees < 22.5 || angleInDegrees >= 157.5) {
                    // 水平方向
                    neighbor1 = magnitudes[y][x - 1];
                    neighbor2 = magnitudes[y][x + 1];
                } else if (angleInDegrees < 67.5) {
                    // 45度方向
                    neighbor1 = magnitudes[y - 1][x + 1];
                    neighbor2 = magnitudes[y + 1][x - 1];
                } else if (angleInDegrees < 112.5) {
                    // 垂直方向
                    neighbor1 = magnitudes[y - 1][x];
                    neighbor2 = magnitudes[y + 1][x];
                } else {
                    // 135度方向
                    neighbor1 = magnitudes[y - 1][x - 1];
                    neighbor2 = magnitudes[y + 1][x + 1];
                }
                
                // 非极大值抑制
                if (mag >= neighbor1 && mag >= neighbor2) {
                    suppressed.push({ x, y, magnitude: mag, direction: angle });
                }
            }
        }
        
        return suppressed;
    }
    
    // 双阈值检测
    doubleThreshold(gradients, lowThreshold, highThreshold) {
        const strongEdges = [];
        const weakEdges = [];
        
        gradients.forEach(grad => {
            if (grad.magnitude >= highThreshold) {
                strongEdges.push({ ...grad, type: 'strong' });
            } else if (grad.magnitude >= lowThreshold) {
                weakEdges.push({ ...grad, type: 'weak' });
            }
        });
        
        return [...strongEdges, ...weakEdges];
    }
    
    // 边缘连接 - 连接弱边缘到强边缘
    edgeTracking(edges) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        
        // 创建边缘类型矩阵
        const edgeMap = Array(height).fill().map(() => Array(width).fill('none'));
        
        edges.forEach(edge => {
            if (edge.x >= 0 && edge.x < width && edge.y >= 0 && edge.y < height) {
                edgeMap[edge.y][edge.x] = edge.type || 'strong';
            }
        });
        
        // 连接弱边缘
        const directions = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]];
        
        const connectedEdges = [];
        
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                if (edgeMap[y][x] === 'strong') {
                    connectedEdges.push({ x, y, type: 'strong' });
                } else if (edgeMap[y][x] === 'weak') {
                    // 检查周围是否有强边缘
                    const hasStrongNeighbor = directions.some(([dx, dy]) => {
                        const nx = x + dx;
                        const ny = y + dy;
                        return edgeMap[ny] && edgeMap[ny][nx] === 'strong';
                    });
                    
                    if (hasStrongNeighbor) {
                        connectedEdges.push({ x, y, type: 'connected' });
                    }
                }
            }
        }
        
        return connectedEdges;
    }
    
    // 杂志风格处理 - 高对比度和饱和度
    applyMagazineStyle() {
        let data = new Uint8ClampedArray(this.processedImageData.data);
        
        // 增强对比度和饱和度
        for (let i = 0; i < data.length; i += 4) {
            // 获取HSL值进行饱和度调整
            const r = data[i] / 255;
            const g = data[i + 1] / 255;
            const b = data[i + 2] / 255;
            
            const max = Math.max(r, g, b);
            const min = Math.min(r, g, b);
            const diff = max - min;
            
            // 增强对比度
            const contrastFactor = 1.3;
            data[i] = Math.min(255, Math.max(0, (r - 0.5) * contrastFactor + 0.5) * 255);
            data[i + 1] = Math.min(255, Math.max(0, (g - 0.5) * contrastFactor + 0.5) * 255);
            data[i + 2] = Math.min(255, Math.max(0, (b - 0.5) * contrastFactor + 0.5) * 255);
            
            // 饱和度增强
            if (diff > 0) {
                const saturationBoost = 1.2;
                const l = (max + min) / 2;
                const s = l > 0.5 ? diff / (2 - max - min) : diff / (max + min);
                
                const newS = Math.min(1, s * saturationBoost);
                const c = (1 - Math.abs(2 * l - 1)) * newS;
                const x = c * (1 - Math.abs(((max === r ? (g - b) / diff : max === g ? (b - r) / diff + 2 : (r - g) / diff + 4)) % 6 - 1));
                const m = l - c / 2;
                
                // 重新计算RGB
                // 简化处理，保持原有逻辑
            }
        }
        
        return new ImageData(data, this.processedImageData.width, this.processedImageData.height);
    }
    
    // 白板风格处理 - 高对比度黑白
    applyWhiteboardStyle() {
        const grayscale = this.applyGrayscale();
        const data = new Uint8ClampedArray(grayscale.data);
        
        // 应用更激进的二值化
        const threshold = this.calculateAdaptiveThreshold(grayscale) + 20;
        
        for (let i = 0; i < data.length; i += 4) {
            const gray = data[i];
            // 白板风格：更倾向于白色背景
            const binaryValue = gray > threshold - 30 ? 255 : 0;
            data[i] = binaryValue;
            data[i + 1] = binaryValue;
            data[i + 2] = binaryValue;
        }
        
        // 额外的形态学处理来清理噪点
        const cleaned = this.morphologicalCleaning(data);
        
        return new ImageData(cleaned, this.processedImageData.width, this.processedImageData.height);
    }
    
    // 形态学清理 - 去除小噪点
    morphologicalCleaning(data) {
        const width = this.processedImageData.width;
        const height = this.processedImageData.height;
        const result = new Uint8ClampedArray(data.length);
        
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                const centerIdx = (y * width + x) * 4;
                
                // 计算3x3邻域的平均值
                let sum = 0;
                let count = 0;
                
                for (let dy = -1; dy <= 1; dy++) {
                    for (let dx = -1; dx <= 1; dx++) {
                        const idx = ((y + dy) * width + (x + dx)) * 4;
                        sum += data[idx];
                        count++;
                    }
                }
                
                const avg = sum / count;
                const value = avg > 127 ? 255 : 0;
                
                result[centerIdx] = value;
                result[centerIdx + 1] = value;
                result[centerIdx + 2] = value;
                result[centerIdx + 3] = data[centerIdx + 3];
            }
        }
        
        return result;
    }
}

// 导出模块
if (typeof module !== 'undefined' && module.exports) {
    module.exports = AdvancedImageProcessor;
} else {
    window.AdvancedImageProcessor = AdvancedImageProcessor;
}