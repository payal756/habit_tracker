const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const Task = require('../models/Task');

// GET all tasks for the logged-in user
router.get('/', auth, async (req, res) => {
  try {
    // This should only return tasks belonging to the authenticated user
    const tasks = await Task.find({ 
      user: req.user.id,  // Filter by user ID from JWT token
      isActive: true 
    }).sort('-createdAt');
    
    console.log(`User ${req.user.id} has ${tasks.length} tasks`);
    res.json(tasks);
  } catch (err) {
    console.error('Error fetching tasks:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// CREATE a new task for the logged-in user
router.post('/', auth, async (req, res) => {
  try {
    const { title, category } = req.body;
    
    if (!title || !category) {
      return res.status(400).json({ error: 'Title and category are required' });
    }
    
    const lockedUntil = new Date();
    lockedUntil.setDate(lockedUntil.getDate() + 21);
    
    // IMPORTANT: Associate task with the logged-in user
    const task = new Task({
      user: req.user.id,  // This links the task to the user
      title,
      category,
      lockedUntil,
      isActive: true,
    });
    
    await task.save();
    console.log(`Task created for user ${req.user.id}: ${title}`);
    res.status(201).json(task);
  } catch (err) {
    console.error('Error creating task:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// UPDATE task (only if user owns it)
router.put('/:id', auth, async (req, res) => {
  try {
    // Find task that belongs to the user
    const task = await Task.findOne({
      _id: req.params.id,
      user: req.user.id,  // Ensure user owns the task
      isActive: true,
    });
    
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    const now = new Date();
    if (task.lockedUntil > now) {
      return res.status(403).json({ 
        error: 'Task is locked for 21 days',
        lockedUntil: task.lockedUntil 
      });
    }
    
    const { title, category } = req.body;
    if (title) task.title = title;
    if (category) task.category = category;
    
    await task.save();
    res.json(task);
  } catch (err) {
    console.error('Error updating task:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE task (soft delete)
router.delete('/:id', auth, async (req, res) => {
  try {
    const task = await Task.findOne({
      _id: req.params.id,
      user: req.user.id,  // Ensure user owns the task
    });
    
    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }
    
    const now = new Date();
    if (task.lockedUntil > now) {
      return res.status(403).json({ 
        error: 'Task is locked for 21 days and cannot be deleted',
        lockedUntil: task.lockedUntil 
      });
    }
    
    task.isActive = false;
    await task.save();
    
    res.json({ message: 'Task deleted successfully' });
  } catch (err) {
    console.error('Error deleting task:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;