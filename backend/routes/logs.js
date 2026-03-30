const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const DailyLog = require('../models/DailyLog');
const Task = require('../models/Task');
const User = require('../models/User');  // Add this line

// Get today's log
router.get('/today', auth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    let log = await DailyLog.findOne({ user: req.user.id, date: today });
    
    if (!log) {
      const tasks = await Task.find({ user: req.user.id, isActive: true });
      const completions = tasks.map(t => ({ taskId: t._id, completed: false }));
      
      log = new DailyLog({ user: req.user.id, date: today, completions });
      await log.save();
    }
    
    res.json(log);
  } catch (err) {
    console.error('Error getting today\'s log:', err);
    res.status(500).json({ error: err.message });
  }
});

// Update today's log
router.put('/today', auth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    let log = await DailyLog.findOne({ user: req.user.id, date: today });
    if (!log) {
      // Create log if it doesn't exist
      const tasks = await Task.find({ user: req.user.id, isActive: true });
      const completions = tasks.map(t => ({ taskId: t._id, completed: false }));
      
      log = new DailyLog({ user: req.user.id, date: today, completions });
    }
    
    // Update completions
    log.completions = req.body.completions;
    await log.save();
    
    // Calculate coins earned
    const completed = log.completions.filter(c => c.completed).length;
    const total = log.completions.length;
    const rate = total > 0 ? (completed / total) * 100 : 0;
    
    let coins = 0;
    if (rate === 100) coins = 10;
    else if (rate >= 80) coins = 5;
    else if (rate >= 50) coins = 2;
    
    if (coins > 0) {
      await User.findByIdAndUpdate(req.user.id, { $inc: { coins: coins } });
      console.log(`💰 User ${req.user.id} earned ${coins} coins!`);
    }
    
    res.json({ log, coinsEarned: coins });
  } catch (err) {
    console.error('Error updating log:', err);
    res.status(500).json({ error: err.message });
  }
});

// Get logs for date range
router.get('/range', auth, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const logs = await DailyLog.find({
      user: req.user.id,
      date: {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      },
    }).sort('date');
    
    res.json(logs);
  } catch (err) {
    console.error('Error getting logs range:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;