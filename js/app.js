class DocumentScanner {
    constructor() {
        this.currentStream = null;
        this.currentFacingMode = 'environment';
        this.capturedImages = [];
        this.processedImages = [];
        this.imageProcessor = new ImageProcessor();
        this.currentEditingIndex = -1;
        this.draggedElement = null;
        this.touchStartPos = null;
        this.zoomLevel = 1;
        this.ocrResults = [];
        this.init();
    }

    init() {
        this.bindEvents();
        this.waitForOpenCV();
    }

    waitForOpenCV() {
        if (typeof cv !== 'undefined') {
            console.log('OpenCV.js loaded successfully');
        } else {
            setTimeout(() => this.waitForOpenCV(), 100);
        }
    }


    bindEvents() {
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => this.switchTab(e.target.dataset.tab));
        });

        // Camera controls
        document.getElementById('start-camera').addEventListener('click', () => this.startCamera());
        document.getElementById('capture').addEventListener('click', () => this.capturePhoto());
        document.getElementById('switch-camera').addEventListener('click', () => this.switchCamera());

        // File upload
        const uploadArea = document.getElementById('upload-area');
        const fileInput = document.getElementById('file-input');

        uploadArea.addEventListener('click', () => fileInput.click());
        uploadArea.addEventListener('dragover', (e) => this.handleDragOver(e));
        uploadArea.addEventListener('drop', (e) => this.handleDrop(e));
        fileInput.addEventListener('change', (e) => this.handleFileSelect(e));

        // Processing controls
        document.getElementById('clear-all').addEventListener('click', () => this.clearAll());
        document.getElementById('preview-processing').addEventListener('click', () => this.previewProcessing());
        document.getElementById('process-images').addEventListener('click', () => this.processImages());
        document.getElementById('back-to-preview').addEventListener('click', () => this.backToPreview());
        document.getElementById('confirm-processing').addEventListener('click', () => this.confirmProcessing());
        document.getElementById('download-files').addEventListener('click', () => this.downloadFiles());
        document.getElementById('start-over').addEventListener('click', () => this.startOver());

        // Modal controls
        document.getElementById('close-editor').addEventListener('click', () => this.closeEditor());
        document.getElementById('close-fullscreen').addEventListener('click', () => this.closeFullscreen());
        document.getElementById('auto-detect').addEventListener('click', () => this.autoDetectEdges());
        document.getElementById('rotate-left').addEventListener('click', () => this.rotateImage(-90));
        document.getElementById('rotate-right').addEventListener('click', () => this.rotateImage(90));
        document.getElementById('apply-changes').addEventListener('click', () => this.applyChanges());

        // Fullscreen controls
        document.getElementById('zoom-in').addEventListener('click', () => this.zoomImage(1.2));
        document.getElementById('zoom-out').addEventListener('click', () => this.zoomImage(0.8));
        document.getElementById('zoom-reset').addEventListener('click', () => this.resetZoom());

        // Touch and gesture events
        this.bindTouchEvents();
        this.bindDragAndDrop();
    }

    switchTab(tabName) {
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
        document.getElementById(`${tabName}-tab`).classList.add('active');

        // Stop camera if switching away from camera tab
        if (tabName !== 'camera' && this.currentStream) {
            this.stopCamera();
        }
    }

    async startCamera() {
        try {
            const constraints = {
                video: {
                    facingMode: this.currentFacingMode,
                    width: { ideal: 1920 },
                    height: { ideal: 1080 }
                }
            };

            this.currentStream = await navigator.mediaDevices.getUserMedia(constraints);
            const video = document.getElementById('video');
            video.srcObject = this.currentStream;

            document.getElementById('start-camera').style.display = 'none';
            document.getElementById('capture').style.display = 'inline-block';
            document.getElementById('switch-camera').style.display = 'inline-block';

        } catch (error) {
            console.error('Error accessing camera:', error);
            alert('无法访问摄像头，请检查权限设置');
        }
    }

    stopCamera() {
        if (this.currentStream) {
            this.currentStream.getTracks().forEach(track => track.stop());
            this.currentStream = null;
            
            document.getElementById('start-camera').style.display = 'inline-block';
            document.getElementById('capture').style.display = 'none';
            document.getElementById('switch-camera').style.display = 'none';
        }
    }

    async switchCamera() {
        this.currentFacingMode = this.currentFacingMode === 'environment' ? 'user' : 'environment';
        this.stopCamera();
        await this.startCamera();
    }

    capturePhoto() {
        const video = document.getElementById('video');
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');

        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        ctx.drawImage(video, 0, 0);

        canvas.toBlob((blob) => {
            const file = new File([blob], `captured_${Date.now()}.jpg`, { type: 'image/jpeg' });
            this.addImage(file);
        }, 'image/jpeg', 0.9);
    }

    handleDragOver(e) {
        e.preventDefault();
        e.stopPropagation();
        document.getElementById('upload-area').classList.add('dragover');
    }

    handleDrop(e) {
        e.preventDefault();
        e.stopPropagation();
        document.getElementById('upload-area').classList.remove('dragover');
        
        const files = Array.from(e.dataTransfer.files).filter(file => file.type.startsWith('image/'));
        files.forEach(file => this.addImage(file));
    }

    handleFileSelect(e) {
        const files = Array.from(e.target.files);
        files.forEach(file => this.addImage(file));
        e.target.value = '';
    }

    addImage(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            const imageData = {
                file: file,
                dataUrl: e.target.result,
                id: Date.now() + Math.random()
            };
            
            this.capturedImages.push(imageData);
            this.updateImagePreview();
            this.showPreviewSection();
        };
        reader.readAsDataURL(file);
    }

    updateImagePreview() {
        const imageList = document.getElementById('image-list');
        imageList.innerHTML = '';
        imageList.className = 'image-list sortable';

        this.capturedImages.forEach((imageData, index) => {
            const imageItem = document.createElement('div');
            imageItem.className = 'image-item';
            imageItem.draggable = true;
            imageItem.dataset.index = index;
            imageItem.innerHTML = `
                <img src="${imageData.dataUrl}" alt="Document ${index + 1}" onclick="scanner.openFullscreen(${index})">
                <div class="image-controls">
                    <button class="control-btn edit-btn" onclick="scanner.editImage(${index})" title="编辑">✏</button>
                    <button class="control-btn rotate-btn" onclick="scanner.quickRotate(${index})" title="旋转">↻</button>
                    <button class="control-btn remove-btn" onclick="scanner.removeImage(${index})" title="删除">×</button>
                </div>
            `;
            imageList.appendChild(imageItem);
        });
    }

    removeImage(index) {
        this.capturedImages.splice(index, 1);
        this.updateImagePreview();
        
        if (this.capturedImages.length === 0) {
            this.hidePreviewSection();
        }
    }

    clearAll() {
        this.capturedImages = [];
        this.processedImages = [];
        this.updateImagePreview();
        this.hidePreviewSection();
        this.hideProcessingSection();
        this.hideResultSection();
    }

    showPreviewSection() {
        document.getElementById('preview-section').style.display = 'block';
    }

    hidePreviewSection() {
        document.getElementById('preview-section').style.display = 'none';
    }

    showProcessingSection() {
        document.getElementById('processing-section').style.display = 'block';
    }

    hideProcessingSection() {
        document.getElementById('processing-section').style.display = 'none';
    }

    showResultSection() {
        document.getElementById('result-section').style.display = 'block';
    }

    hideResultSection() {
        document.getElementById('result-section').style.display = 'none';
    }

    updateProgress(percent, status) {
        document.getElementById('progress').style.width = percent + '%';
        document.getElementById('status-text').textContent = status;
    }

    async processImages() {
        if (this.capturedImages.length === 0) return;

        this.showProcessingSection();
        this.processedImages = [];

        for (let i = 0; i < this.capturedImages.length; i++) {
            const progress = ((i + 1) / this.capturedImages.length) * 100;
            this.updateProgress(progress, `正在处理第 ${i + 1}/${this.capturedImages.length} 张图片...`);

            try {
                const processedImage = await this.processImage(this.capturedImages[i]);
                this.processedImages.push(processedImage);
            } catch (error) {
                console.error('Image processing error:', error);
            }

            await new Promise(resolve => setTimeout(resolve, 100));
        }

        this.updateProgress(100, '图片处理完成，正在生成PDF...');
        
        setTimeout(() => {
            this.hideProcessingSection();
            this.showResultSection();
        }, 500);
    }

    async processImage(imageData) {
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => {
                try {
                    const processedDataUrl = this.enhanceImage(img);
                    resolve(processedDataUrl);
                } catch (error) {
                    console.error('Error processing image:', error);
                    resolve(imageData.dataUrl);
                }
            };
            img.src = imageData.dataUrl;
        });
    }

    enhanceImage(img) {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        
        canvas.width = img.width;
        canvas.height = img.height;
        ctx.drawImage(img, 0, 0);

        if (typeof cv !== 'undefined') {
            try {
                const src = cv.imread(canvas);
                const dst = new cv.Mat();
                const gray = new cv.Mat();
                
                // Convert to grayscale
                cv.cvtColor(src, gray, cv.COLOR_RGBA2GRAY);
                
                // Apply Gaussian blur to reduce noise
                const blurred = new cv.Mat();
                cv.GaussianBlur(gray, blurred, new cv.Size(5, 5), 0);
                
                // Enhance contrast using adaptive threshold
                cv.adaptiveThreshold(blurred, dst, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 11, 2);
                
                // Apply morphological operations to clean up
                const kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(3, 3));
                cv.morphologyEx(dst, dst, cv.MORPH_CLOSE, kernel);
                
                cv.imshow(canvas, dst);
                
                // Cleanup
                src.delete();
                dst.delete();
                gray.delete();
                blurred.delete();
                kernel.delete();
                
            } catch (error) {
                console.error('OpenCV processing error:', error);
                // Fallback to basic contrast enhancement
                this.enhanceContrast(ctx, canvas.width, canvas.height);
            }
        } else {
            // Fallback enhancement without OpenCV
            this.enhanceContrast(ctx, canvas.width, canvas.height);
        }

        return canvas.toDataURL('image/jpeg', 0.9);
    }

    enhanceContrast(ctx, width, height) {
        const imageData = ctx.getImageData(0, 0, width, height);
        const data = imageData.data;
        
        // Simple contrast and brightness adjustment
        const contrast = 1.2;
        const brightness = 10;
        
        for (let i = 0; i < data.length; i += 4) {
            // Apply contrast and brightness to RGB channels
            data[i] = Math.min(255, Math.max(0, contrast * data[i] + brightness));     // Red
            data[i + 1] = Math.min(255, Math.max(0, contrast * data[i + 1] + brightness)); // Green
            data[i + 2] = Math.min(255, Math.max(0, contrast * data[i + 2] + brightness)); // Blue
        }
        
        ctx.putImageData(imageData, 0, 0);
    }

    async downloadPDF() {
        try {
            const pdfDoc = await PDFLib.PDFDocument.create();
            
            for (const imageDataUrl of this.processedImages) {
                const imageBytes = this.dataUrlToBytes(imageDataUrl);
                const image = await pdfDoc.embedJpg(imageBytes);
                
                // A4 size in points (595.28 x 841.89)
                const page = pdfDoc.addPage([595.28, 841.89]);
                const { width: pageWidth, height: pageHeight } = page.getSize();
                
                // Calculate image dimensions to fit A4 page
                const imgAspectRatio = image.width / image.height;
                const pageAspectRatio = pageWidth / pageHeight;
                
                let imgWidth, imgHeight;
                if (imgAspectRatio > pageAspectRatio) {
                    imgWidth = pageWidth - 40; // 20pt margin on each side
                    imgHeight = imgWidth / imgAspectRatio;
                } else {
                    imgHeight = pageHeight - 40; // 20pt margin on top and bottom
                    imgWidth = imgHeight * imgAspectRatio;
                }
                
                const x = (pageWidth - imgWidth) / 2;
                const y = (pageHeight - imgHeight) / 2;
                
                page.drawImage(image, {
                    x: x,
                    y: y,
                    width: imgWidth,
                    height: imgHeight,
                });
            }
            
            const pdfBytes = await pdfDoc.save();
            const blob = new Blob([pdfBytes], { type: 'application/pdf' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `scanned_documents_${new Date().toISOString().slice(0, 19).replace(/:/g, '-')}.pdf`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            
        } catch (error) {
            console.error('PDF generation error:', error);
            alert('PDF生成失败，请重试');
        }
    }

    dataUrlToBytes(dataUrl) {
        const byteString = atob(dataUrl.split(',')[1]);
        const arrayBuffer = new ArrayBuffer(byteString.length);
        const uint8Array = new Uint8Array(arrayBuffer);
        
        for (let i = 0; i < byteString.length; i++) {
            uint8Array[i] = byteString.charCodeAt(i);
        }
        
        return arrayBuffer;
    }

    startOver() {
        this.clearAll();
        this.switchTab('camera');
    }

    // 新增功能方法

    // 编辑图片
    editImage(index) {
        this.currentEditingIndex = index;
        const imageData = this.capturedImages[index];
        this.openImageEditor(imageData.dataUrl);
    }

    // 打开图片编辑器
    openImageEditor(dataUrl) {
        const modal = document.getElementById('image-editor-modal');
        const canvas = document.getElementById('editor-canvas');
        const ctx = canvas.getContext('2d');
        
        const img = new Image();
        img.onload = () => {
            canvas.width = img.width;
            canvas.height = img.height;
            ctx.drawImage(img, 0, 0);
            
            // 自动检测边缘
            this.autoDetectEdges();
        };
        img.src = dataUrl;
        
        modal.classList.add('show');
    }

    // 关闭编辑器
    closeEditor() {
        document.getElementById('image-editor-modal').classList.remove('show');
    }

    // 自动检测边缘
    autoDetectEdges() {
        const canvas = document.getElementById('editor-canvas');
        const corners = this.imageProcessor.detectDocumentEdges(canvas);
        this.updateCornerPoints(corners);
    }

    // 更新角点位置
    updateCornerPoints(corners) {
        const canvas = document.getElementById('editor-canvas');
        const rect = canvas.getBoundingClientRect();
        const scaleX = rect.width / canvas.width;
        const scaleY = rect.height / canvas.height;
        
        const cornerPoints = document.querySelectorAll('.corner-point');
        corners.forEach((corner, index) => {
            if (cornerPoints[index]) {
                cornerPoints[index].style.left = (corner[0] * scaleX) + 'px';
                cornerPoints[index].style.top = (corner[1] * scaleY) + 'px';
            }
        });
        
        this.bindCornerDrag();
    }

    // 绑定角点拖拽
    bindCornerDrag() {
        const cornerPoints = document.querySelectorAll('.corner-point');
        cornerPoints.forEach(point => {
            point.addEventListener('mousedown', this.startCornerDrag.bind(this));
            point.addEventListener('touchstart', this.startCornerDrag.bind(this));
        });
    }

    // 开始拖拽角点
    startCornerDrag(e) {
        e.preventDefault();
        const point = e.target;
        this.isDragging = true;
        this.currentCorner = point;
        
        document.addEventListener('mousemove', this.dragCorner.bind(this));
        document.addEventListener('mouseup', this.stopCornerDrag.bind(this));
        document.addEventListener('touchmove', this.dragCorner.bind(this));
        document.addEventListener('touchend', this.stopCornerDrag.bind(this));
    }

    // 拖拽角点
    dragCorner(e) {
        if (!this.isDragging) return;
        
        const canvas = document.getElementById('editor-canvas');
        const rect = canvas.getBoundingClientRect();
        
        const clientX = e.clientX || (e.touches && e.touches[0].clientX);
        const clientY = e.clientY || (e.touches && e.touches[0].clientY);
        
        const x = clientX - rect.left;
        const y = clientY - rect.top;
        
        this.currentCorner.style.left = x + 'px';
        this.currentCorner.style.top = y + 'px';
    }

    // 停止拖拽角点
    stopCornerDrag() {
        this.isDragging = false;
        this.currentCorner = null;
        
        document.removeEventListener('mousemove', this.dragCorner.bind(this));
        document.removeEventListener('mouseup', this.stopCornerDrag.bind(this));
        document.removeEventListener('touchmove', this.dragCorner.bind(this));
        document.removeEventListener('touchend', this.stopCornerDrag.bind(this));
    }

    // 旋转图片
    rotateImage(angle) {
        const canvas = document.getElementById('editor-canvas');
        const dataUrl = this.imageProcessor.rotateImage(canvas, angle * Math.PI / 180);
        
        const img = new Image();
        img.onload = () => {
            canvas.width = img.width;
            canvas.height = img.height;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(img, 0, 0);
            this.autoDetectEdges();
        };
        img.src = dataUrl;
    }

    // 快速旋转
    quickRotate(index) {
        const imageData = this.capturedImages[index];
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        
        const img = new Image();
        img.onload = () => {
            canvas.width = img.width;
            canvas.height = img.height;
            ctx.drawImage(img, 0, 0);
            
            const rotatedDataUrl = this.imageProcessor.rotateImage(canvas, Math.PI / 2);
            this.capturedImages[index].dataUrl = rotatedDataUrl;
            this.updateImagePreview();
        };
        img.src = imageData.dataUrl;
    }

    // 应用修改
    applyChanges() {
        const canvas = document.getElementById('editor-canvas');
        const corners = this.getCurrentCorners();
        
        // 应用透视校正
        const correctedDataUrl = this.imageProcessor.perspectiveTransform(canvas, corners);
        
        if (this.currentEditingIndex >= 0) {
            this.capturedImages[this.currentEditingIndex].dataUrl = correctedDataUrl;
            this.updateImagePreview();
        }
        
        this.closeEditor();
    }

    // 获取当前角点坐标
    getCurrentCorners() {
        const canvas = document.getElementById('editor-canvas');
        const rect = canvas.getBoundingClientRect();
        const scaleX = canvas.width / rect.width;
        const scaleY = canvas.height / rect.height;
        
        const cornerPoints = document.querySelectorAll('.corner-point');
        return Array.from(cornerPoints).map(point => {
            const x = (parseFloat(point.style.left) || 0) * scaleX;
            const y = (parseFloat(point.style.top) || 0) * scaleY;
            return [x, y];
        });
    }

    // 全屏预览
    openFullscreen(index) {
        const modal = document.getElementById('fullscreen-modal');
        const img = document.getElementById('fullscreen-image');
        img.src = this.capturedImages[index].dataUrl;
        this.resetZoom();
        modal.classList.add('show');
    }

    // 关闭全屏
    closeFullscreen() {
        document.getElementById('fullscreen-modal').classList.remove('show');
    }

    // 缩放图片
    zoomImage(factor) {
        this.zoomLevel *= factor;
        const img = document.getElementById('fullscreen-image');
        img.style.transform = `scale(${this.zoomLevel})`;
    }

    // 重置缩放
    resetZoom() {
        this.zoomLevel = 1;
        const img = document.getElementById('fullscreen-image');
        img.style.transform = 'scale(1)';
    }

    // 预览处理效果
    async previewProcessing() {
        if (this.capturedImages.length === 0) return;

        this.hidePreviewSection();
        this.showProcessingPreviewSection();
        
        const processedList = document.getElementById('processed-image-list');
        processedList.innerHTML = '';

        for (let i = 0; i < this.capturedImages.length; i++) {
            const original = this.capturedImages[i];
            const processed = await this.processImagePreview(original);
            
            const item = document.createElement('div');
            item.className = 'processed-image-item';
            item.innerHTML = `
                <div class="before-after">
                    <div class="before">
                        <img src="${original.dataUrl}" alt="原图">
                    </div>
                    <div class="after">
                        <img src="${processed}" alt="处理后">
                    </div>
                </div>
                <div class="labels">
                    <div>原图</div>
                    <div>处理后</div>
                </div>
            `;
            processedList.appendChild(item);
        }
    }

    // 处理单张图片预览
    async processImagePreview(imageData) {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        
        return new Promise((resolve) => {
            const img = new Image();
            img.onload = () => {
                canvas.width = img.width;
                canvas.height = img.height;
                ctx.drawImage(img, 0, 0);
                
                // 自动检测并校正
                const corners = this.imageProcessor.detectDocumentEdges(canvas);
                const corrected = this.imageProcessor.perspectiveTransform(canvas, corners);
                
                // 增强处理
                const enhanced = this.imageProcessor.enhanceImage(canvas);
                resolve(enhanced);
            };
            img.src = imageData.dataUrl;
        });
    }

    // 返回预览
    backToPreview() {
        this.hideProcessingPreviewSection();
        this.showPreviewSection();
    }

    // 确认处理
    async confirmProcessing() {
        await this.processImages();
    }

    // 显示/隐藏处理预览区域
    showProcessingPreviewSection() {
        document.getElementById('processing-preview-section').style.display = 'block';
    }

    hideProcessingPreviewSection() {
        document.getElementById('processing-preview-section').style.display = 'none';
    }

    // 下载文件
    async downloadFiles() {
        const format = document.querySelector('input[name="format"]:checked').value;
        const pageSize = document.querySelector('input[name="pageSize"]:checked').value;
        const enableOCR = document.getElementById('ocr-text').checked;

        if (enableOCR) {
            await this.performOCR();
        }

        if (format === 'pdf') {
            await this.generatePDF(pageSize);
        } else if (format === 'zip') {
            await this.generateZIP();
        }
    }

    // 执行OCR
    async performOCR() {
        this.ocrResults = [];
        for (const imageDataUrl of this.processedImages) {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            
            const img = new Image();
            img.src = imageDataUrl;
            await new Promise(resolve => {
                img.onload = () => {
                    canvas.width = img.width;
                    canvas.height = img.height;
                    ctx.drawImage(img, 0, 0);
                    resolve();
                };
            });
            
            const text = await this.imageProcessor.recognizeText(canvas);
            this.ocrResults.push(text);
        }
    }

    // 生成PDF
    async generatePDF(pageSize) {
        const pageSizes = {
            a4: [595.28, 841.89],
            a3: [841.89, 1190.55],
            letter: [612, 792]
        };
        
        const [pageWidth, pageHeight] = pageSizes[pageSize];
        
        try {
            const pdfDoc = await PDFLib.PDFDocument.create();
            
            for (let i = 0; i < this.processedImages.length; i++) {
                const imageBytes = this.imageProcessor.dataUrlToBytes(this.processedImages[i]);
                const image = await pdfDoc.embedJpg(imageBytes);
                
                const page = pdfDoc.addPage([pageWidth, pageHeight]);
                
                // 计算图片尺寸
                const imgAspectRatio = image.width / image.height;
                const pageAspectRatio = pageWidth / pageHeight;
                
                let imgWidth, imgHeight;
                if (imgAspectRatio > pageAspectRatio) {
                    imgWidth = pageWidth - 40;
                    imgHeight = imgWidth / imgAspectRatio;
                } else {
                    imgHeight = pageHeight - 40;
                    imgWidth = imgHeight * imgAspectRatio;
                }
                
                const x = (pageWidth - imgWidth) / 2;
                const y = (pageHeight - imgHeight) / 2;
                
                page.drawImage(image, { x, y, width: imgWidth, height: imgHeight });
                
                // 添加OCR文本
                if (this.ocrResults[i]) {
                    page.drawText(this.ocrResults[i], {
                        x: 20,
                        y: 20,
                        size: 10,
                        color: PDFLib.rgb(0, 0, 0)
                    });
                }
            }
            
            const pdfBytes = await pdfDoc.save();
            this.downloadFile(pdfBytes, 'application/pdf', `scanned_documents_${pageSize}.pdf`);
            
        } catch (error) {
            console.error('PDF generation error:', error);
            alert('PDF生成失败，请重试');
        }
    }

    // 生成ZIP
    async generateZIP() {
        try {
            const zipBlob = await this.imageProcessor.generateZip(this.processedImages);
            this.downloadFile(zipBlob, 'application/zip', 'scanned_documents.zip');
        } catch (error) {
            console.error('ZIP generation error:', error);
            alert('ZIP生成失败，请重试');
        }
    }

    // 下载文件
    downloadFile(data, mimeType, filename) {
        const blob = data instanceof Blob ? data : new Blob([data], { type: mimeType });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    // 绑定触摸事件
    bindTouchEvents() {
        // 双击放大
        document.addEventListener('dblclick', (e) => {
            if (e.target.tagName === 'IMG' && e.target.closest('.image-item')) {
                const index = parseInt(e.target.closest('.image-item').dataset.index);
                this.openFullscreen(index);
            }
        });

        // 触摸手势
        let touchStartDistance = 0;
        document.addEventListener('touchstart', (e) => {
            if (e.touches.length === 2) {
                touchStartDistance = this.getTouchDistance(e.touches[0], e.touches[1]);
            }
        });

        document.addEventListener('touchmove', (e) => {
            if (e.touches.length === 2 && document.getElementById('fullscreen-modal').classList.contains('show')) {
                e.preventDefault();
                const currentDistance = this.getTouchDistance(e.touches[0], e.touches[1]);
                const scale = currentDistance / touchStartDistance;
                this.zoomLevel *= scale;
                const img = document.getElementById('fullscreen-image');
                img.style.transform = `scale(${this.zoomLevel})`;
                touchStartDistance = currentDistance;
            }
        });
    }

    // 计算触摸距离
    getTouchDistance(touch1, touch2) {
        const dx = touch1.clientX - touch2.clientX;
        const dy = touch1.clientY - touch2.clientY;
        return Math.sqrt(dx * dx + dy * dy);
    }

    // 绑定拖拽排序
    bindDragAndDrop() {
        const imageList = document.getElementById('image-list');
        
        imageList.addEventListener('dragstart', (e) => {
            if (e.target.closest('.image-item')) {
                this.draggedElement = e.target.closest('.image-item');
                this.draggedElement.classList.add('dragging');
            }
        });

        imageList.addEventListener('dragover', (e) => {
            e.preventDefault();
            const afterElement = this.getDragAfterElement(imageList, e.clientY);
            if (afterElement == null) {
                imageList.appendChild(this.draggedElement);
            } else {
                imageList.insertBefore(this.draggedElement, afterElement);
            }
        });

        imageList.addEventListener('dragend', () => {
            if (this.draggedElement) {
                this.draggedElement.classList.remove('dragging');
                this.reorderImages();
                this.draggedElement = null;
            }
        });
    }

    // 获取拖拽位置
    getDragAfterElement(container, y) {
        const draggableElements = [...container.querySelectorAll('.image-item:not(.dragging)')];
        
        return draggableElements.reduce((closest, child) => {
            const box = child.getBoundingClientRect();
            const offset = y - box.top - box.height / 2;
            
            if (offset < 0 && offset > closest.offset) {
                return { offset: offset, element: child };
            } else {
                return closest;
            }
        }, { offset: Number.NEGATIVE_INFINITY }).element;
    }

    // 重新排序图片
    reorderImages() {
        const imageItems = document.querySelectorAll('.image-item');
        const newOrder = [];
        
        imageItems.forEach(item => {
            const index = parseInt(item.dataset.index);
            newOrder.push(this.capturedImages[index]);
        });
        
        this.capturedImages = newOrder;
        this.updateImagePreview();
    }
}

// Initialize the application
const scanner = new DocumentScanner();