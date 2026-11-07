/**
 * FinLoop Landing Page JS Logic
 */

document.addEventListener('DOMContentLoaded', () => {
    
    // ==========================================
    // 1. Sticky Header Header Adjustments
    // ==========================================
    const header = document.getElementById('header');
    
    const handleScroll = () => {
        if (window.scrollY > 50) {
            header.classList.add('scrolled');
        } else {
            header.classList.remove('scrolled');
        }
    };
    
    window.addEventListener('scroll', handleScroll);
    handleScroll(); // Run once on load

    // ==========================================
    // 2. Mobile Drawer Navigation Menu
    // ==========================================
    const mobileToggle = document.getElementById('mobile-toggle');
    const navMenu = document.getElementById('nav-menu');
    const toggleIcon = mobileToggle.querySelector('i');
    
    const toggleMenu = () => {
        navMenu.classList.toggle('open');
        const isOpen = navMenu.classList.contains('open');
        
        // Switch menu icons
        if (isOpen) {
            toggleIcon.classList.remove('fa-bars');
            toggleIcon.classList.add('fa-xmark');
        } else {
            toggleIcon.classList.remove('fa-xmark');
            toggleIcon.classList.add('fa-bars');
        }
    };
    
    mobileToggle.addEventListener('click', toggleMenu);
    
    // Close menu when a navigation link is clicked
    const navLinks = document.querySelectorAll('.nav-link, .mobile-only-btn');
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            if (navMenu.classList.contains('open')) {
                toggleMenu();
            }
        });
    });

    // ==========================================
    // 3. Scroll Reveal Animation using IntersectionObserver
    // ==========================================
    const revealElements = document.querySelectorAll('.scroll-reveal');
    
    if ('IntersectionObserver' in window) {
        const observerOptions = {
            root: null,
            threshold: 0.15,
            rootMargin: '0px 0px -50px 0px'
        };
        
        const revealObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('revealed');
                    observer.unobserve(entry.target); // Trigger only once
                }
            });
        }, observerOptions);
        
        revealElements.forEach(el => revealObserver.observe(el));
    } else {
        // Fallback for older browsers
        revealElements.forEach(el => el.classList.add('revealed'));
    }

    // ==========================================
    // 4. Hero Mockup Phone Interactive Tabs (with Autoplay)
    // ==========================================
    const mockupNavBtns = document.querySelectorAll('.phone-nav-btn');
    const mockupTabContents = document.querySelectorAll('.app-tab-content');
    let mockupAutoplayInterval;
    let currentMockupTabIdx = 0;
    let isMockupUserInteracted = false;

    // Switch mockup screen content function
    const switchMockupTab = (targetId, clickedBtn) => {
        // Remove active class from buttons and contents
        mockupNavBtns.forEach(btn => btn.classList.remove('active'));
        mockupTabContents.forEach(content => {
            content.classList.remove('active');
            content.style.opacity = '0';
        });

        // Set active to targeted button and content
        clickedBtn.classList.add('active');
        const targetContent = document.getElementById(targetId);
        if (targetContent) {
            targetContent.classList.add('active');
            // Trigger a minor repaint for smooth transition
            setTimeout(() => {
                targetContent.style.opacity = '1';
            }, 50);
        }
    };

    // Click handler for phone mockup buttons
    mockupNavBtns.forEach((btn, index) => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            isMockupUserInteracted = true;
            clearInterval(mockupAutoplayInterval); // Stop autoplay
            
            const targetId = btn.getAttribute('data-target');
            currentMockupTabIdx = index;
            switchMockupTab(targetId, btn);
        });
    });

    // Start autoplay for mockup screens
    const startMockupAutoplay = () => {
        mockupAutoplayInterval = setInterval(() => {
            if (!isMockupUserInteracted) {
                currentMockupTabIdx = (currentMockupTabIdx + 1) % mockupNavBtns.length;
                const nextBtn = mockupNavBtns[currentMockupTabIdx];
                const targetId = nextBtn.getAttribute('data-target');
                switchMockupTab(targetId, nextBtn);
            }
        }, 5000); // Switch every 5 seconds
    };

    startMockupAutoplay();

    // ==========================================
    // 5. Screenshots Section Gallery Slider
    // ==========================================
    const showcaseTabs = document.querySelectorAll('.showcase-tab');
    const screenshotImg = document.getElementById('active-screenshot-img');
    const infoDescText = document.getElementById('screenshot-info-desc');

    showcaseTabs.forEach(tab => {
        tab.addEventListener('click', () => {
            if (tab.classList.contains('active')) return;
            
            // Remove active status from all tabs
            showcaseTabs.forEach(t => t.classList.remove('active'));
            // Activate selected tab
            tab.classList.add('active');

            const newImgSrc = tab.getAttribute('data-img');
            const newDesc = tab.getAttribute('data-desc');

            // Smooth cross-fade transition
            screenshotImg.style.opacity = '0';
            infoDescText.style.opacity = '0';

            setTimeout(() => {
                // Update elements content
                screenshotImg.setAttribute('src', newImgSrc);
                infoDescText.textContent = newDesc;

                // Fade back in
                screenshotImg.style.opacity = '1';
                infoDescText.style.opacity = '1';
            }, 250); // Matches the css transitions
        });
    });

    // ==========================================
    // 6. Accordion Panel FAQ
    // ==========================================
    const faqItems = document.querySelectorAll('.faq-item');

    faqItems.forEach(item => {
        const questionBtn = item.querySelector('.faq-question');
        const answerPanel = item.querySelector('.faq-answer');

        questionBtn.addEventListener('click', () => {
            const isActive = item.classList.contains('active');

            // Close other open FAQ panels (accordion behaviour)
            faqItems.forEach(otherItem => {
                if (otherItem !== item && otherItem.classList.contains('active')) {
                    otherItem.classList.remove('active');
                    otherItem.querySelector('.faq-answer').style.maxHeight = '0px';
                }
            });

            // Toggle current FAQ panel
            if (isActive) {
                item.classList.remove('active');
                answerPanel.style.maxHeight = '0px';
            } else {
                item.classList.add('active');
                // Calculate dynamic height to allow smooth CSS transition
                answerPanel.style.maxHeight = answerPanel.scrollHeight + 'px';
            }
        });
    });
});
