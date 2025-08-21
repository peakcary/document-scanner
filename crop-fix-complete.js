// 完全重写裁剪功能，修复位置和按钮问题

// 重新设计拖拽点位置系统
const cropFixCSS = `
/* 修复后的裁剪拖拽点样式 */
.crop-handle {
    position: absolute;
    width: 24px;
    height: 24px;
    background: #4299e1;
    border: 3px solid white;
    border-radius: 50%;
    cursor: pointer;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
    z-index: 10;
    /* 重要：使用transform而不是top/left偏移 */
    transform-origin: center;
}

.crop-handle:hover {
    background: #3182ce;
    transform: scale(1.1);
}

/* 精确的位置定义 */
.crop-handle-nw { 
    top: 0; 
    left: 0; 
    cursor: nw-resize; 
    transform: translate(-50%, -50%);
}
.crop-handle-n { 
    top: 0; 
    left: 50%; 
    cursor: n-resize; 
    transform: translate(-50%, -50%);
}
.crop-handle-ne { 
    top: 0; 
    right: 0; 
    cursor: ne-resize; 
    transform: translate(50%, -50%);
}
.crop-handle-e { 
    top: 50%; 
    right: 0; 
    cursor: e-resize; 
    transform: translate(50%, -50%);
}
.crop-handle-se { 
    bottom: 0; 
    right: 0; 
    cursor: se-resize; 
    transform: translate(50%, 50%);
}
.crop-handle-s { 
    bottom: 0; 
    left: 50%; 
    cursor: s-resize; 
    transform: translate(-50%, 50%);
}
.crop-handle-sw { 
    bottom: 0; 
    left: 0; 
    cursor: sw-resize; 
    transform: translate(-50%, 50%);
}
.crop-handle-w { 
    top: 50%; 
    left: 0; 
    cursor: w-resize; 
    transform: translate(-50%, -50%);
}

/* 移动端更大的拖拽点 */
@media (hover: none) and (pointer: coarse) {
    .crop-handle {
        width: 32px;
        height: 32px;
        border: 4px solid white;
    }
}

/* 确保按钮可见 */
.crop-controls {
    margin: 20px 0;
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    justify-content: center;
    padding: 10px;
    background: #f8f9fa;
    border-radius: 10px;
}

.crop-action-btn {
    background: #ffffff;
    border: 2px solid #dee2e6;
    border-radius: 8px;
    padding: 15px 25px;
    cursor: pointer;
    font-size: 1.1rem;
    font-weight: 600;
    transition: all 0.3s ease;
    min-width: 100px;
    text-align: center;
    display: inline-block;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.crop-action-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

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

/* 移动端按钮优化 */
@media (hover: none) and (pointer: coarse) {
    .crop-action-btn {
        padding: 18px 30px;
        font-size: 1.2rem;
        min-width: 120px;
        min-height: 60px;
    }
}
`;