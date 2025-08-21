// 修复移动端裁剪和图片显示问题

// 1. 确保图片上传后立即显示
function handleFiles(files, source = 'upload') {
    const validFiles = files.filter(file => file.type.startsWith('image/'));
    
    if (validFiles.length === 0) {
        showNotification('请选择有效的图片文件！', 'error');
        return;
    }
    
    // 添加到现有图片列表
    const startIndex = selectedImages.length;
    validFiles.forEach(file => {
        selectedImages.push({
            file: file,
            processed: false,
            croppedData: null,
            source: source
        });
    });
    
    // 立即更新预览显示
    updatePreview();
    
    const sourceText = source === 'camera' ? '拍照' : '上传';
    showNotification(`${sourceText}成功，共 ${validFiles.length} 张图片`, 'success');
    
    // 短暂延迟后自动打开第一张图片的裁剪界面
    setTimeout(() => {
        openCropModal(startIndex);
    }, 500);
}

// 2. 修复移动端触摸支持
function bindCropEvents() {
    const cropSelection = document.getElementById('crop-selection');
    const handles = document.querySelectorAll('.crop-handle');
    
    // 移动端和桌面端统一的事件处理
    function addUniversalEvents(element, startCallback) {
        // 鼠标事件
        element.addEventListener('mousedown', startCallback);
        
        // 触摸事件
        element.addEventListener('touchstart', (e) => {
            e.preventDefault();
            // 将触摸事件转换为鼠标事件格式
            const touch = e.touches[0];
            const mouseEvent = {
                clientX: touch.clientX,
                clientY: touch.clientY,
                preventDefault: () => e.preventDefault(),
                stopPropagation: () => e.stopPropagation()
            };
            startCallback(mouseEvent);
        }, { passive: false });
    }
    
    // 绑定选择框拖拽事件
    addUniversalEvents(cropSelection, startDrag);
    
    // 绑定调整点事件
    handles.forEach(handle => {
        addUniversalEvents(handle, (e) => {
            e.stopPropagation();
            startResize(e, handle.dataset.handle);
        });
    });
    
    // 全局移动和结束事件
    function onMove(e) {
        if (!isDragging) return;
        
        // 统一处理鼠标和触摸事件
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        
        const mockEvent = { clientX, clientY };
        onMouseMove(mockEvent);
    }
    
    function onEnd(e) {
        stopDrag();
    }
    
    // 鼠标事件
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onEnd);
    
    // 触摸事件
    document.addEventListener('touchmove', onMove, { passive: false });
    document.addEventListener('touchend', onEnd, { passive: false });
    document.addEventListener('touchcancel', onEnd, { passive: false });
}

// 3. 优化裁剪区域初始化
function initializeCropArea() {
    const cropImage = document.getElementById('crop-image');
    const cropSelection = document.getElementById('crop-selection');
    const container = document.getElementById('crop-image-container');
    
    // 等待图片完全加载
    if (!cropImage.complete || cropImage.naturalWidth === 0) {
        setTimeout(initializeCropArea, 100);
        return;
    }
    
    // 获取图片实际显示尺寸
    const rect = cropImage.getBoundingClientRect();
    imageRect = {
        width: rect.width,
        height: rect.height,
        left: rect.left,
        top: rect.top
    };
    
    // 设置初始裁剪区域为图片的80%居中
    const margin = 0.1;
    cropRect = {
        x: imageRect.width * margin,
        y: imageRect.height * margin,
        width: imageRect.width * (1 - 2 * margin),
        height: imageRect.height * (1 - 2 * margin)
    };
    
    updateCropSelection();
    updateCropPreview();
    bindCropEvents();
}