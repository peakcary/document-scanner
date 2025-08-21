// 终极裁剪功能修复 - 解决所有已知问题
// 修复问题：
// 1. 拖拽点位置错位
// 2. 移动端触摸事件无法使用  
// 3. 确定按钮不可见
// 4. 坐标系统混乱

const ultimateCropFix = `
/* ==== 修复后的裁剪样式 ==== */
.crop-handle {
    position: absolute;
    width: 20px;
    height: 20px;
    background: #ffffff;
    border: 2px solid #4299e1;
    border-radius: 50%;
    cursor: pointer;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    z-index: 15;
    /* 关键修复：简化transform */
}

.crop-handle:hover {
    background: #4299e1;
    border-color: #ffffff;
    transform: scale(1.2);
}

/* 修复拖拽点定位 - 使用margin而不是transform */
.crop-handle-nw { 
    top: -10px; 
    left: -10px; 
    cursor: nw-resize; 
}
.crop-handle-n { 
    top: -10px; 
    left: calc(50% - 10px); 
    cursor: n-resize; 
}
.crop-handle-ne { 
    top: -10px; 
    right: -10px; 
    cursor: ne-resize; 
}
.crop-handle-e { 
    top: calc(50% - 10px); 
    right: -10px; 
    cursor: e-resize; 
}
.crop-handle-se { 
    bottom: -10px; 
    right: -10px; 
    cursor: se-resize; 
}
.crop-handle-s { 
    bottom: -10px; 
    left: calc(50% - 10px); 
    cursor: s-resize; 
}
.crop-handle-sw { 
    bottom: -10px; 
    left: -10px; 
    cursor: sw-resize; 
}
.crop-handle-w { 
    top: calc(50% - 10px); 
    left: -10px; 
    cursor: w-resize; 
}

/* 移动端更大更易操作的拖拽点 */
@media (hover: none) and (pointer: coarse) {
    .crop-handle {
        width: 32px;
        height: 32px;
        border: 3px solid #4299e1;
        background: rgba(255, 255, 255, 0.95);
    }
    
    .crop-handle-nw { top: -16px; left: -16px; }
    .crop-handle-n { top: -16px; left: calc(50% - 16px); }
    .crop-handle-ne { top: -16px; right: -16px; }
    .crop-handle-e { top: calc(50% - 16px); right: -16px; }
    .crop-handle-se { bottom: -16px; right: -16px; }
    .crop-handle-s { bottom: -16px; left: calc(50% - 16px); }
    .crop-handle-sw { bottom: -16px; left: -16px; }
    .crop-handle-w { top: calc(50% - 16px); left: -16px; }
}

/* 增强按钮可见性 */
.crop-controls {
    margin: 25px 0;
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    justify-content: center;
    padding: 20px;
    background: rgba(248, 249, 250, 0.95);
    border-radius: 12px;
    border: 1px solid #e2e8f0;
}

.crop-action-btn {
    background: #ffffff;
    border: 2px solid #cbd5e0;
    border-radius: 10px;
    padding: 16px 24px;
    cursor: pointer;
    font-size: 1.1rem;
    font-weight: 600;
    transition: all 0.2s ease;
    min-width: 110px;
    text-align: center;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    color: #2d3748;
}

.crop-action-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

.crop-action-btn:active {
    transform: translateY(0px);
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* 按钮颜色区分 */
.apply-btn {
    background: #48bb78 !important;
    border-color: #48bb78 !important;
    color: white !important;
}

.cancel-btn {
    background: #f56565 !important;
    border-color: #f56565 !important;
    color: white !important;
}

.reset-btn {
    background: #ed8936 !important;
    border-color: #ed8936 !important;
    color: white !important;
}

.rotate-btn {
    background: #4299e1 !important;
    border-color: #4299e1 !important;
    color: white !important;
}

/* 移动端按钮优化 */
@media (hover: none) and (pointer: coarse) {
    .crop-action-btn {
        padding: 20px 28px;
        font-size: 1.3rem;
        min-width: 130px;
        min-height: 64px;
        border-width: 3px;
    }
    
    .crop-controls {
        padding: 25px;
        gap: 20px;
    }
}

/* 修复裁剪选择框 */
#crop-selection {
    border: 2px solid #4299e1 !important;
    box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.6) !important;
    /* 确保选择框可见性 */
    background: rgba(66, 153, 225, 0.1) !important;
}

/* 网格线增强 */
.crop-grid-line {
    background: rgba(255, 255, 255, 0.7) !important;
    box-shadow: 0 0 1px rgba(0, 0, 0, 0.5);
}

.crop-grid-h {
    height: 1px !important;
}

.crop-grid-v {
    width: 1px !important;
}
`;

// 修复JavaScript逻辑
const fixedCropJS = `
// 修复的裁剪功能 JavaScript

// 全局变量重新初始化
let isDragging = false;
let dragHandle = null;
let startPos = { x: 0, y: 0 };
let cropRect = { x: 0, y: 0, width: 0, height: 0 };
let imageRect = { width: 0, height: 0, left: 0, top: 0 };
let currentCropIndex = 0;

// 修复的初始化函数
function initializeCropArea() {
    const cropImage = document.getElementById('crop-image');
    const cropSelection = document.getElementById('crop-selection');
    const container = document.getElementById('crop-image-container');
    
    // 确保图片完全加载
    if (!cropImage.complete || cropImage.naturalWidth === 0) {
        setTimeout(initializeCropArea, 100);
        return;
    }
    
    // 获取图片实际显示尺寸 - 相对于容器
    const containerRect = container.getBoundingClientRect();
    const imgRect = cropImage.getBoundingClientRect();
    
    // 修复：使用相对于容器的坐标
    imageRect = {
        width: cropImage.offsetWidth,  // 使用offsetWidth而不是getBoundingClientRect
        height: cropImage.offsetHeight,
        left: 0,  // 相对于容器的位置
        top: 0
    };
    
    console.log('Image rect:', imageRect);
    
    // 设置初始裁剪区域为图片的80%居中
    const margin = 0.1;
    cropRect = {
        x: imageRect.width * margin,
        y: imageRect.height * margin,
        width: imageRect.width * (1 - 2 * margin),
        height: imageRect.height * (1 - 2 * margin)
    };
    
    console.log('Crop rect:', cropRect);
    
    updateCropSelection();
    updateCropPreview();
    bindCropEvents();
}

// 修复的事件绑定函数
function bindCropEvents() {
    const cropSelection = document.getElementById('crop-selection');
    const handles = document.querySelectorAll('.crop-handle');
    
    console.log('Binding events to', handles.length, 'handles');
    
    // 清除之前的事件监听器
    document.removeEventListener('mousemove', onMouseMove);
    document.removeEventListener('mouseup', stopDrag);
    document.removeEventListener('touchmove', onTouchMove);
    document.removeEventListener('touchend', stopDrag);
    
    // 统一事件处理函数
    function addUniversalEvents(element, startCallback) {
        // 移除旧的事件监听器
        element.onmousedown = null;
        element.ontouchstart = null;
        
        // 鼠标事件
        element.addEventListener('mousedown', (e) => {
            e.preventDefault();
            startCallback(e);
        });
        
        // 触摸事件
        element.addEventListener('touchstart', (e) => {
            e.preventDefault();
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
    
    // 全局事件监听器
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', stopDrag);
    document.addEventListener('touchmove', onTouchMove, { passive: false });
    document.addEventListener('touchend', stopDrag, { passive: false });
    document.addEventListener('touchcancel', stopDrag, { passive: false });
}

// 修复的触摸移动处理
function onTouchMove(e) {
    e.preventDefault();
    if (!isDragging) return;
    
    const touch = e.touches[0];
    const mouseEvent = {
        clientX: touch.clientX,
        clientY: touch.clientY
    };
    onMouseMove(mouseEvent);
}

// 修复的鼠标移动处理
function onMouseMove(e) {
    if (!isDragging) return;
    
    const container = document.getElementById('crop-image-container');
    const containerRect = container.getBoundingClientRect();
    
    // 转换为相对于容器的坐标
    const containerX = e.clientX - containerRect.left;
    const containerY = e.clientY - containerRect.top;
    
    const deltaX = containerX - startPos.x;
    const deltaY = containerY - startPos.y;
    
    if (dragHandle === 'move') {
        // 移动整个选择框
        let newX = cropRect.x + deltaX;
        let newY = cropRect.y + deltaY;
        
        // 边界检测
        newX = Math.max(0, Math.min(newX, imageRect.width - cropRect.width));
        newY = Math.max(0, Math.min(newY, imageRect.height - cropRect.height));
        
        cropRect.x = newX;
        cropRect.y = newY;
    } else {
        // 调整选择框大小
        resizeCropRect(deltaX, deltaY, dragHandle);
    }
    
    updateCropSelection();
    updateCropPreview();
    
    startPos = { x: containerX, y: containerY };
}

// 修复的开始拖拽
function startDrag(e) {
    isDragging = true;
    dragHandle = 'move';
    
    const container = document.getElementById('crop-image-container');
    const containerRect = container.getBoundingClientRect();
    
    startPos = { 
        x: e.clientX - containerRect.left, 
        y: e.clientY - containerRect.top 
    };
    
    console.log('Start drag at:', startPos);
}

// 修复的开始调整大小
function startResize(e, handle) {
    isDragging = true;
    dragHandle = handle;
    
    const container = document.getElementById('crop-image-container');
    const containerRect = container.getBoundingClientRect();
    
    startPos = { 
        x: e.clientX - containerRect.left, 
        y: e.clientY - containerRect.top 
    };
    
    console.log('Start resize:', handle, 'at:', startPos);
}

// 修复的停止拖拽
function stopDrag() {
    isDragging = false;
    dragHandle = null;
    console.log('Stop drag');
}

// 优化的调整大小函数
function resizeCropRect(deltaX, deltaY, handle) {
    const minSize = 50;
    const maxWidth = imageRect.width;
    const maxHeight = imageRect.height;
    
    const oldRect = {...cropRect};
    
    switch(handle) {
        case 'nw':
            cropRect.x = Math.max(0, Math.min(cropRect.x + deltaX, cropRect.x + cropRect.width - minSize));
            cropRect.y = Math.max(0, Math.min(cropRect.y + deltaY, cropRect.y + cropRect.height - minSize));
            cropRect.width = oldRect.width + (oldRect.x - cropRect.x);
            cropRect.height = oldRect.height + (oldRect.y - cropRect.y);
            break;
        case 'n':
            cropRect.y = Math.max(0, Math.min(cropRect.y + deltaY, cropRect.y + cropRect.height - minSize));
            cropRect.height = oldRect.height + (oldRect.y - cropRect.y);
            break;
        case 'ne':
            cropRect.y = Math.max(0, Math.min(cropRect.y + deltaY, cropRect.y + cropRect.height - minSize));
            cropRect.width = Math.max(minSize, Math.min(cropRect.width + deltaX, maxWidth - cropRect.x));
            cropRect.height = oldRect.height + (oldRect.y - cropRect.y);
            break;
        case 'e':
            cropRect.width = Math.max(minSize, Math.min(cropRect.width + deltaX, maxWidth - cropRect.x));
            break;
        case 'se':
            cropRect.width = Math.max(minSize, Math.min(cropRect.width + deltaX, maxWidth - cropRect.x));
            cropRect.height = Math.max(minSize, Math.min(cropRect.height + deltaY, maxHeight - cropRect.y));
            break;
        case 's':
            cropRect.height = Math.max(minSize, Math.min(cropRect.height + deltaY, maxHeight - cropRect.y));
            break;
        case 'sw':
            cropRect.x = Math.max(0, Math.min(cropRect.x + deltaX, cropRect.x + cropRect.width - minSize));
            cropRect.width = oldRect.width + (oldRect.x - cropRect.x);
            cropRect.height = Math.max(minSize, Math.min(cropRect.height + deltaY, maxHeight - cropRect.y));
            break;
        case 'w':
            cropRect.x = Math.max(0, Math.min(cropRect.x + deltaX, cropRect.x + cropRect.width - minSize));
            cropRect.width = oldRect.width + (oldRect.x - cropRect.x);
            break;
    }
}
`;

module.exports = { ultimateCropFix, fixedCropJS };