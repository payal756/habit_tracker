const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const DailyLog = require('../models/DailyLog');
const Task = require('../models/Task');

router.get('/', auth, async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const tasks = await Task.find({ user: req.user.id, isActive: true });
    const logs = await DailyLog.find({
      user: req.user.id,
      date: { $gte: new Date(today.getTime() - 6 * 24 * 60 * 60 * 1000) }
    }).sort('date');
    
    const dailyCompletions = [];
    let totalCompleted = 0;
    let currentStreak = 0;
    let bestStreak = 0;
    
    for (let i = 0; i < 7; i++) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      
      const log = logs.find(l => l.date.toDateString() === date.toDateString());
      let percentage = 0;
      
      if (log && tasks.length > 0) {
        const completed = log.completions.filter(c => c.completed).length;
        percentage = (completed / tasks.length) * 100;
        totalCompleted += completed;
        
        if (percentage >= 80) {
          currentStreak++;
          bestStreak = Math.max(bestStreak, currentStreak);
        } else {
          currentStreak = 0;
        }
      } else {
        currentStreak = 0;
      }
      
      dailyCompletions.unshift({
        date: date.toISOString().split('T')[0],
        percentage: Math.round(percentage),
      });
    }
    
    const overall = tasks.length > 0 ? (totalCompleted / (tasks.length * 7)) * 100 : 0;
    const consistency = Math.min(100, Math.round(bestStreak * 15 + overall * 0.5));
    
    res.json({
      dailyCompletions,
      overallCompletion: Math.round(overall),
      currentStreak,
      bestStreak,
      consistencyScore: consistency,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;